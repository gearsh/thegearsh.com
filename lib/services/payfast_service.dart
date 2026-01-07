import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// PayFast Payment Service for Gearsh
/// Handles payment processing for artist bookings
class PayFastService {
  // PayFast Configuration
  // TODO: Replace with your actual PayFast credentials
  static const String _merchantId = '10000100'; // Sandbox merchant ID
  static const String _merchantKey = '46f0cd694581a'; // Sandbox merchant key
  static const String _passphrase = 'jt7NOE43FZPn'; // Sandbox passphrase

  // URLs
  static const String _sandboxUrl = 'https://sandbox.payfast.co.za/eng/process';
  static const String _liveUrl = 'https://www.payfast.co.za/eng/process';

  // Set to false for production
  static const bool _isSandbox = true;

  static String get _paymentUrl => _isSandbox ? _sandboxUrl : _liveUrl;

  /// Generate PayFast payment data for a booking
  static Map<String, String> generatePaymentData({
    required String bookingId,
    required double amount,
    required String itemName,
    required String itemDescription,
    required String customerEmail,
    required String customerFirstName,
    required String customerLastName,
    String? returnUrl,
    String? cancelUrl,
    String? notifyUrl,
  }) {
    // Convert amount to cents and format
    final amountFormatted = amount.toStringAsFixed(2);

    final data = <String, String>{
      'merchant_id': _merchantId,
      'merchant_key': _merchantKey,
      'return_url': returnUrl ?? 'https://gearsh.com/booking/success',
      'cancel_url': cancelUrl ?? 'https://gearsh.com/booking/cancel',
      'notify_url': notifyUrl ?? 'https://gearsh.com/api/payfast/notify',
      'name_first': customerFirstName,
      'name_last': customerLastName,
      'email_address': customerEmail,
      'm_payment_id': bookingId,
      'amount': amountFormatted,
      'item_name': itemName,
      'item_description': itemDescription,
    };

    // Generate signature
    data['signature'] = _generateSignature(data);

    return data;
  }

  /// Generate MD5 signature for PayFast
  static String _generateSignature(Map<String, String> data) {
    // Sort data alphabetically by key
    final sortedKeys = data.keys.toList()..sort();

    // Build parameter string
    final paramString = sortedKeys
        .where((key) => data[key]?.isNotEmpty ?? false)
        .map((key) => '$key=${Uri.encodeComponent(data[key]!)}')
        .join('&');

    // Add passphrase if set
    final stringToHash = _passphrase.isNotEmpty
        ? '$paramString&passphrase=${Uri.encodeComponent(_passphrase)}'
        : paramString;

    // Generate MD5 hash
    return md5.convert(utf8.encode(stringToHash)).toString();
  }

  /// Launch PayFast payment page
  static Future<bool> launchPayment({
    required String bookingId,
    required double amount,
    required String artistName,
    required String serviceName,
    required String customerEmail,
    required String customerFirstName,
    required String customerLastName,
  }) async {
    final paymentData = generatePaymentData(
      bookingId: bookingId,
      amount: amount,
      itemName: 'Gearsh Booking - $artistName',
      itemDescription: serviceName,
      customerEmail: customerEmail,
      customerFirstName: customerFirstName,
      customerLastName: customerLastName,
    );

    // Build URL with query parameters
    final uri = Uri.parse(_paymentUrl).replace(
      queryParameters: paymentData,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching PayFast: $e');
    }
    return false;
  }

  /// Verify PayFast payment notification (ITN)
  /// This should be called from your backend server
  static bool verifyPaymentNotification(Map<String, String> postData) {
    // Remove signature from data for verification
    final signature = postData.remove('signature');

    // Generate signature from received data
    final generatedSignature = _generateSignature(postData);

    // Compare signatures
    return signature == generatedSignature;
  }

  /// Get payment status text
  static String getPaymentStatusText(String status) {
    switch (status) {
      case 'COMPLETE':
        return 'Payment Successful';
      case 'FAILED':
        return 'Payment Failed';
      case 'PENDING':
        return 'Payment Pending';
      case 'CANCELLED':
        return 'Payment Cancelled';
      default:
        return 'Unknown Status';
    }
  }
}

/// Payment result model
class PayFastPaymentResult {
  final bool success;
  final String? paymentId;
  final String? status;
  final String? message;
  final double? amount;

  PayFastPaymentResult({
    required this.success,
    this.paymentId,
    this.status,
    this.message,
    this.amount,
  });

  factory PayFastPaymentResult.fromNotification(Map<String, String> data) {
    final paymentStatus = data['payment_status'] ?? '';
    return PayFastPaymentResult(
      success: paymentStatus == 'COMPLETE',
      paymentId: data['pf_payment_id'],
      status: paymentStatus,
      message: PayFastService.getPaymentStatusText(paymentStatus),
      amount: double.tryParse(data['amount_gross'] ?? ''),
    );
  }
}

