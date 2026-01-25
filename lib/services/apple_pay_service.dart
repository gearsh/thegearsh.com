// Gearsh App - Apple Pay Service
// Handles Apple Pay payments for booking services
// Uses the pay package for Flutter

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pay/pay.dart';

/// Apple Pay configuration for Gearsh
class ApplePayConfig {
  /// Merchant ID from Apple Developer account
  static const String merchantId = 'merchant.com.gearsh.app';

  /// Merchant name displayed on payment sheet
  static const String merchantName = 'Gearsh';

  /// Country code (ISO 3166-1 alpha-2)
  static const String countryCode = 'ZA';

  /// Currency code (ISO 4217)
  static const String currencyCode = 'ZAR';

  /// Supported networks
  static const List<String> supportedNetworks = [
    'visa',
    'masterCard',
    'amex',
    'discover',
  ];
}

/// Payment item for Apple Pay
class GearshPaymentItem {
  final String label;
  final double amount;
  final bool isPending;

  const GearshPaymentItem({
    required this.label,
    required this.amount,
    this.isPending = false,
  });

  PaymentItem toPaymentItem() {
    return PaymentItem(
      label: label,
      amount: amount.toStringAsFixed(2),
      status: isPending ? PaymentItemStatus.pending : PaymentItemStatus.final_price,
    );
  }
}

/// Result of an Apple Pay transaction
class ApplePayResult {
  final bool success;
  final String? transactionId;
  final String? error;
  final Map<String, dynamic>? paymentData;

  const ApplePayResult._({
    required this.success,
    this.transactionId,
    this.error,
    this.paymentData,
  });

  factory ApplePayResult.success({
    required String transactionId,
    Map<String, dynamic>? paymentData,
  }) {
    return ApplePayResult._(
      success: true,
      transactionId: transactionId,
      paymentData: paymentData,
    );
  }

  factory ApplePayResult.failure(String error) {
    return ApplePayResult._(
      success: false,
      error: error,
    );
  }

  factory ApplePayResult.cancelled() {
    return const ApplePayResult._(
      success: false,
      error: 'Payment was cancelled',
    );
  }
}

/// Apple Pay Service for Gearsh
class ApplePayService {
  static final ApplePayService _instance = ApplePayService._internal();
  factory ApplePayService() => _instance;
  ApplePayService._internal();

  Pay? _payClient;
  bool _isInitialized = false;

  /// Check if Apple Pay is available on this device
  Future<bool> isAvailable() async {
    // Only available on iOS
    if (kIsWeb || !Platform.isIOS) {
      return false;
    }

    try {
      _payClient ??= Pay({
        PayProvider.apple_pay: PaymentConfiguration.fromJsonString(_applePayConfig),
      });

      final result = await _payClient!.userCanPay(PayProvider.apple_pay);
      _isInitialized = result;
      return result;
    } catch (e) {
      debugPrint('Apple Pay availability check failed: $e');
      return false;
    }
  }

  /// Process a payment with Apple Pay
  Future<ApplePayResult> processPayment({
    required String bookingId,
    required double amount,
    required String artistName,
    required String serviceName,
    double? serviceFee,
  }) async {
    if (!_isInitialized) {
      final available = await isAvailable();
      if (!available) {
        return ApplePayResult.failure('Apple Pay is not available on this device');
      }
    }

    try {
      // Build payment items
      final items = <PaymentItem>[
        PaymentItem(
          label: serviceName,
          amount: amount.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      if (serviceFee != null && serviceFee > 0) {
        items.add(PaymentItem(
          label: 'Service Fee',
          amount: serviceFee.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ));
      }

      // Add total
      final total = amount + (serviceFee ?? 0);
      items.add(PaymentItem(
        label: ApplePayConfig.merchantName,
        amount: total.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ));

      // Show Apple Pay sheet
      final result = await _payClient!.showPaymentSelector(
        PayProvider.apple_pay,
        items,
      );

      // Process the result
      if (result.isNotEmpty) {
        // Extract transaction data
        final transactionId = 'ap_${DateTime.now().millisecondsSinceEpoch}_$bookingId';

        debugPrint('Apple Pay payment successful: $transactionId');

        return ApplePayResult.success(
          transactionId: transactionId,
          paymentData: result,
        );
      } else {
        return ApplePayResult.cancelled();
      }
    } catch (e) {
      debugPrint('Apple Pay payment failed: $e');

      if (e.toString().contains('cancel')) {
        return ApplePayResult.cancelled();
      }

      return ApplePayResult.failure('Payment failed: ${e.toString()}');
    }
  }

  /// Get the Apple Pay configuration JSON
  static String get _applePayConfig => '''
{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "${ApplePayConfig.merchantId}",
    "displayName": "${ApplePayConfig.merchantName}",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ${ApplePayConfig.supportedNetworks.map((n) => '"$n"').toList()},
    "countryCode": "${ApplePayConfig.countryCode}",
    "currencyCode": "${ApplePayConfig.currencyCode}",
    "requiredBillingContactFields": ["emailAddress", "name"],
    "requiredShippingContactFields": []
  }
}
''';
}

/// Global instance
final applePayService = ApplePayService();
