"""Clean Gearsh logo — conservative white/fringe removal that preserves the full artwork."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "images" / "gearsh-logo.png"


def neighbor_mask(mask: np.ndarray) -> np.ndarray:
    h, w = mask.shape
    touches = np.zeros((h, w), dtype=bool)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            ys = slice(max(0, dy), h + min(0, dy))
            xs = slice(max(0, dx), w + min(0, dx))
            sy = slice(max(0, -dy), h - max(0, dy))
            sx = slice(max(0, -dx), w - max(0, dx))
            touches[sy, sx] |= mask[ys, xs]
    return touches


def strict_white_flood(rgba: np.ndarray) -> np.ndarray:
    """Remove only pure/near-pure white regions connected to the image border."""
    h, w, _ = rgba.shape
    bg = np.zeros((h, w), dtype=bool)
    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    rgb = rgba[:, :, :3].astype(np.int16)

    def is_strict_white(y: int, x: int) -> bool:
        if rgba[y, x, 3] == 0:
            return True
        r, g, b = rgb[y, x]
        return r >= 242 and g >= 242 and b >= 242

    for x in range(w):
        for y in (0, h - 1):
            if is_strict_white(y, x):
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if is_strict_white(y, x) and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))

    while q:
        y, x = q.popleft()
        bg[y, x] = True
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_strict_white(ny, nx):
                visited[ny, nx] = True
                q.append((ny, nx))

    out = rgba.copy()
    out[bg, 3] = 0
    return out


def peel_light_fringe(rgba: np.ndarray, passes: int = 12) -> np.ndarray:
    """Remove neutral light halos directly bordering transparency."""
    out = rgba.copy()
    alpha = out[:, :, 3].astype(np.float32)
    rgb = out[:, :, :3].astype(np.float32)

    for _ in range(passes):
        transparent = alpha < 8
        if not transparent.any():
            break
        touch = neighbor_mask(transparent) & (alpha >= 8)
        avg = rgb.mean(axis=2)
        spread = rgb.max(axis=2) - rgb.min(axis=2)

        remove = touch & (
            ((avg >= 228) & (spread <= 28))
            | ((avg >= 210) & (spread <= 14))
            | ((rgb[:, :, 0] >= 236) & (rgb[:, :, 1] >= 236) & (rgb[:, :, 2] >= 236))
        )
        if not remove.any():
            break
        alpha[remove] = 0

    out[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    return out


def fix_edge_matte(rgba: np.ndarray) -> np.ndarray:
    """Correct semi-transparent neutral edge pixels for dark UI backgrounds."""
    out = rgba.copy().astype(np.float32)
    a = out[:, :, 3] / 255.0
    rgb = out[:, :, :3]
    edge = (a > 0.05) & (a < 0.95)
    avg = rgb.mean(axis=2)
    spread = rgb.max(axis=2) - rgb.min(axis=2)
    fix = edge & (avg > 175) & (spread < 38)

    visible = rgb * a[..., None]
    for c in range(3):
        channel = visible[:, :, c].copy()
        channel[fix] = visible[:, :, c][fix] / np.maximum(a[fix], 0.12)
        rgb[:, :, c] = channel

    out[:, :, :3] = np.clip(rgb, 0, 255)
    return out.astype(np.uint8)


def polish_alpha(rgba: np.ndarray) -> np.ndarray:
    out = rgba.copy()
    alpha = out[:, :, 3].astype(np.float32)
    alpha_img = Image.fromarray(alpha.astype(np.uint8), mode="L")
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.45))
    polished = np.array(alpha_img, dtype=np.float32)
    polished[alpha < 8] = 0
    polished[alpha > 250] = 255
    out[:, :, 3] = np.clip(polished, 0, 255).astype(np.uint8)
    return out


def process_logo(rgba: np.ndarray) -> np.ndarray:
    opaque_before = int((rgba[:, :, 3] > 0).sum())
    out = strict_white_flood(rgba)
    out = peel_light_fringe(out)
    out = fix_edge_matte(out)
    out = polish_alpha(out)

    opaque_after = int((out[:, :, 3] > 0).sum())
    min_allowed = int(opaque_before * 0.92)
    if opaque_after < min_allowed:
        raise RuntimeError(
            f"Logo cleanup too aggressive: {opaque_after} opaque px vs {opaque_before} before"
        )
    return out


def save_png(rgba: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, mode="RGBA").save(path, format="PNG", optimize=True)


def resize_icon(rgba: np.ndarray, size: int) -> np.ndarray:
    img = Image.fromarray(rgba, mode="RGBA").resize((size, size), Image.Resampling.LANCZOS)
    out = process_logo(np.array(img))
    if size <= 512:
        out = np.array(
            Image.fromarray(out, mode="RGBA").filter(
                ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=3)
            )
        )
    return out


def make_maskable(rgba: np.ndarray, size: int, inset: float = 0.12) -> np.ndarray:
    margin = int(size * inset)
    inner = size - margin * 2
    icon = Image.fromarray(rgba, mode="RGBA").resize((inner, inner), Image.Resampling.LANCZOS)
    canvas = np.zeros((size, size, 4), dtype=np.uint8)
    canvas[margin : margin + inner, margin : margin + inner] = np.array(icon)
    return process_logo(canvas)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source logo: {SOURCE}")

    source = np.array(Image.open(SOURCE).convert("RGBA"))
    cleaned = process_logo(source)

    for name in ("gearsh-logo.png", "gearsh_logo.png", "gearsh.png"):
        save_png(cleaned, ROOT / "assets" / "images" / name)

    icon_dir = ROOT / "web" / "icons"
    save_png(resize_icon(cleaned, 512), icon_dir / "Icon-512.png")
    save_png(resize_icon(cleaned, 192), icon_dir / "Icon-192.png")
    save_png(make_maskable(cleaned, 512), icon_dir / "Icon-maskable-512.png")
    save_png(make_maskable(cleaned, 192), icon_dir / "Icon-maskable-192.png")
    save_png(resize_icon(cleaned, 512), icon_dir / "og-image.png")

    save_png(resize_icon(cleaned, 256), ROOT / "web" / "favicon.png")
    save_png(resize_icon(cleaned, 256), ROOT / "assets" / "images" / "favicon.png")

    a = cleaned
    nw = int(((a[:, :, 0] > 235) & (a[:, :, 1] > 235) & (a[:, :, 2] > 235) & (a[:, :, 3] > 0)).sum())
    op = int((a[:, :, 3] > 0).sum())
    print("Saved cleaned logo assets.")
    print(f"  opaque pixels: {op}")
    print(f"  near-white visible pixels: {nw}")


if __name__ == "__main__":
    main()
