import 'package:flutter/material.dart';

/// A widget that displays prices with discount styling
/// Shows original price crossed out in grey, discount badge, and final price in green
class DiscountPriceWidget extends StatelessWidget {
  final double originalPrice;
  final double discountedPrice;
  final int discountPercent;
  final bool showBadge;
  final double fontSize;
  final bool compact;
  final String currencySymbol;

  const DiscountPriceWidget({
    super.key,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    this.showBadge = true,
    this.fontSize = 14.0,
    this.compact = false,
    this.currencySymbol = 'R',
  });

  // Theme colors
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _red500 = Color(0xFFEF4444);
  static const Color _slate400 = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildFull() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Discount badge
        if (showBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _red500,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-$discountPercent%',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize - 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // Original price (crossed out, grey)
        Text(
          '$currencySymbol${_formatPrice(originalPrice)}',
          style: TextStyle(
            color: _slate400,
            fontSize: fontSize,
            decoration: TextDecoration.lineThrough,
            decorationColor: _slate400,
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 8),
        // Discounted price (highlighted in green)
        Text(
          '$currencySymbol${_formatPrice(discountedPrice)}',
          style: TextStyle(
            color: _green500,
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Discount badge
        if (showBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: _red500,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-$discountPercent%',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize - 4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // Original price (crossed out)
        Text(
          '$currencySymbol${_formatPrice(originalPrice)}',
          style: TextStyle(
            color: _slate400,
            fontSize: fontSize - 2,
            decoration: TextDecoration.lineThrough,
            decorationColor: _slate400,
          ),
        ),
        // Discounted price
        Text(
          '$currencySymbol${_formatPrice(discountedPrice)}',
          style: TextStyle(
            color: _green500,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      // Format with comma separator
      return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return price.toStringAsFixed(0);
  }
}

/// A simpler inline discount display for cards
class InlineDiscountPrice extends StatelessWidget {
  final int originalPrice;
  final int discountedPrice;
  final int discountPercent;
  final double fontSize;
  final String currencySymbol;

  const InlineDiscountPrice({
    super.key,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    this.fontSize = 13.0,
    this.currencySymbol = 'R',
  });

  static const Color _green500 = Color(0xFF22C55E);
  static const Color _red500 = Color(0xFFEF4444);
  static const Color _slate400 = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Discount badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: _red500,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-$discountPercent%',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize - 3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Original price crossed out
        Text(
          '$currencySymbol$originalPrice',
          style: TextStyle(
            color: _slate400,
            fontSize: fontSize - 1,
            decoration: TextDecoration.lineThrough,
            decorationColor: _slate400,
          ),
        ),
        const SizedBox(width: 4),
        // Final price
        Text(
          '$currencySymbol$discountedPrice',
          style: TextStyle(
            color: _green500,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Service card with discount display
class ServiceDiscountPrice extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final double fontSize;
  final String currencySymbol;

  const ServiceDiscountPrice({
    super.key,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.fontSize = 16.0,
    this.currencySymbol = 'R',
  });

  static const Color _green500 = Color(0xFF22C55E);
  static const Color _red500 = Color(0xFFEF4444);
  static const Color _slate400 = Color(0xFF94A3B8);

  bool get hasDiscount => originalPrice != null && discountPercent != null && discountPercent! > 0;

  @override
  Widget build(BuildContext context) {
    if (!hasDiscount) {
      return Text(
        '$currencySymbol${price.toStringAsFixed(0)}',
        style: TextStyle(
          color: _green500,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Discount badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _red500,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$discountPercent% OFF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Original price
        Text(
          '$currencySymbol${originalPrice!.toStringAsFixed(0)}',
          style: TextStyle(
            color: _slate400,
            fontSize: fontSize - 2,
            decoration: TextDecoration.lineThrough,
            decorationColor: _slate400,
            decorationThickness: 2,
          ),
        ),
        // Final price
        Text(
          '$currencySymbol${price.toStringAsFixed(0)}',
          style: TextStyle(
            color: _green500,
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

