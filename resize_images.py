#!/usr/bin/env python3
"""
Batch Image Resizer for Artist Images
Resizes all images in assets/images/artists/ to 400x400 pixels
"""

import os
from pathlib import Path
from PIL import Image
import sys

def resize_image(input_path, output_path, size=400):
    """Resize image to specified size while maintaining aspect ratio"""
    try:
        img = Image.open(input_path)

        # Convert to RGB if necessary (for RGBA, LA, P modes)
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'RGBA':
                background.paste(img, mask=img.split()[-1])
            else:
                background.paste(img)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')

        # Resize to 400x400
        img = img.resize((size, size), Image.Resampling.LANCZOS)

        # Save with appropriate format
        ext = output_path.suffix.lower()
        if ext == '.webp':
            img.save(output_path, 'WEBP', quality=90)
        elif ext == '.png':
            img.save(output_path, 'PNG', optimize=True)
        else:  # .jpg, .jpeg
            img.save(output_path, 'JPEG', quality=90)

        return True
    except Exception as e:
        print(f"Error processing {input_path}: {str(e)}")
        return False

def main():
    artists_dir = Path("assets/images/artists")

    if not artists_dir.exists():
        print(f"❌ Directory not found: {artists_dir}")
        return

    print("=" * 60)
    print("🖼️  IMAGE RESIZER")
    print("=" * 60)
    print(f"\nTarget directory: {artists_dir.absolute()}\n")

    # Get all image files
    image_extensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'}
    image_files = [f for f in artists_dir.iterdir()
                   if f.is_file() and f.suffix.lower() in image_extensions]

    if not image_files:
        print("❌ No image files found!")
        return

    print(f"Found {len(image_files)} images\n")

    resized = 0
    failed = 0

    for idx, image_file in enumerate(image_files, 1):
        print(f"[{idx}/{len(image_files)}] Resizing: {image_file.name}")

        # Create backup
        backup_path = image_file.with_suffix(image_file.suffix + '.bak')
        try:
            import shutil
            shutil.copy2(image_file, backup_path)
        except:
            pass  # Backup optional

        # Resize
        if resize_image(image_file, image_file, size=400):
            print(f"  ✅ Resized to 400x400")
            resized += 1

            # Remove backup if successful
            if backup_path.exists():
                try:
                    backup_path.unlink()
                except:
                    pass
        else:
            print(f"  ❌ Failed to resize")
            failed += 1

    print("\n" + "=" * 60)
    print(f"✅ Successfully resized: {resized}")
    print(f"❌ Failed: {failed}")
    print("=" * 60)
    print("\nAll images are now 400x400 pixels!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Resizing cancelled")
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        sys.exit(1)

