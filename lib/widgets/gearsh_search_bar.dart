import 'package:flutter/material.dart';

/// Gearsh-styled search bar widget for consistent design throughout the app
class GearshSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool showClearButton;
  final bool compact;

  const GearshSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search artists, genres, locations...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.showClearButton = true,
    this.compact = false,
  });

  // Gearsh theme colors
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSearchBar();
    }
    return _buildFullSearchBar();
  }

  Widget _buildFullSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        border: Border.all(
          color: _sky500.withAlpha(77),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _sky500.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient search icon
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_sky400, _cyan500],
            ).createShader(bounds),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Search input
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              autofocus: autofocus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withAlpha(77),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          // Clear button
          if (showClearButton && controller != null && controller!.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller?.clear();
                onClear?.call();
              },
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withAlpha(128),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: _sky500.withAlpha(51), width: 1),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_sky400, _cyan500],
            ).createShader(bounds),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              autofocus: autofocus,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.white.withAlpha(102), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (showClearButton && controller != null && controller!.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller?.clear();
                onClear?.call();
              },
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withAlpha(128),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

/// Search bar with back button for search results screens
class GearshSearchBarWithBack extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBack;
  final VoidCallback? onClear;
  final bool autofocus;

  const GearshSearchBarWithBack({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search artists...',
    this.onChanged,
    this.onBack,
    this.onClear,
    this.autofocus = true,
  });

  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _slate800,
              shape: BoxShape.circle,
              border: Border.all(color: _sky500.withAlpha(51), width: 1),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        // Search field
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: _sky500.withAlpha(77), width: 1),
            ),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_sky400, _cyan500],
                  ).createShader(bounds),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    onChanged: onChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: Colors.white.withAlpha(77), fontSize: 15),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (controller != null && controller!.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller?.clear();
                      onClear?.call();
                    },
                    child: Icon(Icons.close_rounded, color: Colors.white.withAlpha(128), size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
