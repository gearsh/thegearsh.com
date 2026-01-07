// Global Price Display Widget
// Displays prices in the user's selected currency with proper formatting

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/global_config_providers.dart';
import '../services/global_config_service.dart';

/// Displays a price in the current user's currency
class PriceText extends ConsumerWidget {
  final double amount;
  final String? fromCurrency; // Currency code of the original amount
  final TextStyle? style;
  final bool showOriginal; // Show original currency in brackets
  final bool compact; // Use short format (e.g., R87k)

  const PriceText({
    super.key,
    required this.amount,
    this.fromCurrency,
    this.style,
    this.showOriginal = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.read(globalConfigProvider);
    final currentRegion = config.currentRegion;

    double displayAmount = amount;

    // Convert if from a different currency
    if (fromCurrency != null && fromCurrency != currentRegion.currencyCode) {
      final fromRegion = SupportedRegions.all.firstWhere(
        (r) => r.currencyCode == fromCurrency,
        orElse: () => SupportedRegions.southAfrica,
      );
      displayAmount = config.convertCurrency(amount, fromRegion, currentRegion);
    }

    final formattedPrice = compact
        ? config.formatPriceShort(displayAmount)
        : config.formatPrice(displayAmount);

    if (showOriginal && fromCurrency != null && fromCurrency != currentRegion.currencyCode) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: formattedPrice, style: style),
            TextSpan(
              text: ' ($fromCurrency ${amount.toStringAsFixed(0)})',
              style: style?.copyWith(
                fontSize: (style?.fontSize ?? 14) * 0.8,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return Text(formattedPrice, style: style);
  }
}

/// Price range display (e.g., "From R5,000")
class PriceFromText extends ConsumerWidget {
  final double minAmount;
  final String? fromCurrency;
  final TextStyle? style;
  final String prefix;

  const PriceFromText({
    super.key,
    required this.minAmount,
    this.fromCurrency,
    this.style,
    this.prefix = 'From ',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.read(globalConfigProvider);
    final currentRegion = config.currentRegion;

    double displayAmount = minAmount;

    if (fromCurrency != null && fromCurrency != currentRegion.currencyCode) {
      final fromRegion = SupportedRegions.all.firstWhere(
        (r) => r.currencyCode == fromCurrency,
        orElse: () => SupportedRegions.southAfrica,
      );
      displayAmount = config.convertCurrency(minAmount, fromRegion, currentRegion);
    }

    return Text(
      '$prefix${config.formatPrice(displayAmount)}',
      style: style,
    );
  }
}

/// Service fee display with breakdown
class ServiceFeeDisplay extends ConsumerWidget {
  final double bookingAmount;
  final String? fromCurrency;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;

  const ServiceFeeDisplay({
    super.key,
    required this.bookingAmount,
    this.fromCurrency,
    this.labelStyle,
    this.amountStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.read(globalConfigProvider);
    final currentRegion = config.currentRegion;

    double displayAmount = bookingAmount;

    if (fromCurrency != null && fromCurrency != currentRegion.currencyCode) {
      final fromRegion = SupportedRegions.all.firstWhere(
        (r) => r.currencyCode == fromCurrency,
        orElse: () => SupportedRegions.southAfrica,
      );
      displayAmount = config.convertCurrency(bookingAmount, fromRegion, currentRegion);
    }

    final serviceFee = config.calculateServiceFee(displayAmount);
    final total = config.getTotalWithServiceFee(displayAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow('Booking fee', displayAmount, config, labelStyle, amountStyle),
        const SizedBox(height: 8),
        _buildRow('Service fee (12.6%)', serviceFee, config, labelStyle, amountStyle),
        const Divider(color: Colors.white24, height: 24),
        _buildRow('Total', total, config,
          labelStyle?.copyWith(fontWeight: FontWeight.bold),
          amountStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRow(String label, double amount, GlobalConfigService config,
      TextStyle? labelStyle, TextStyle? amountStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? const TextStyle(color: Colors.white70)),
        Text(config.formatPrice(amount), style: amountStyle ?? const TextStyle(color: Colors.white)),
      ],
    );
  }
}

/// Currency badge showing artist's native currency
class CurrencyBadge extends StatelessWidget {
  final String currencyCode;
  final double? size;

  const CurrencyBadge({
    super.key,
    required this.currencyCode,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final region = SupportedRegions.all.firstWhere(
      (r) => r.currencyCode == currencyCode,
      orElse: () => SupportedRegions.southAfrica,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size != null ? size! * 0.4 : 6,
        vertical: size != null ? size! * 0.2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withAlpha(26),
        borderRadius: BorderRadius.circular(size != null ? size! * 0.3 : 4),
        border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(region.flag, style: TextStyle(fontSize: size ?? 12)),
          SizedBox(width: size != null ? size! * 0.2 : 4),
          Text(
            currencyCode,
            style: TextStyle(
              color: const Color(0xFF38BDF8),
              fontSize: size != null ? size! * 0.7 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

