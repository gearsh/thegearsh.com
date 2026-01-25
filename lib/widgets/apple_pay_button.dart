// Gearsh App - Apple Pay Button Widget
// Reusable Apple Pay button for payment flows

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gearsh_app/services/apple_pay_service.dart';

/// Apple Pay button that handles availability check and payment
class GearshApplePayButton extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String artistName;
  final String serviceName;
  final double? serviceFee;
  final VoidCallback? onPaymentStarted;
  final void Function(ApplePayResult result)? onPaymentComplete;
  final double? width;
  final double? height;

  const GearshApplePayButton({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.artistName,
    required this.serviceName,
    this.serviceFee,
    this.onPaymentStarted,
    this.onPaymentComplete,
    this.width,
    this.height,
  });

  @override
  State<GearshApplePayButton> createState() => _GearshApplePayButtonState();
}

class _GearshApplePayButtonState extends State<GearshApplePayButton> {
  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (kIsWeb || !Platform.isIOS) {
      setState(() {
        _isAvailable = false;
        _isChecking = false;
      });
      return;
    }

    final available = await applePayService.isAvailable();
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isChecking = false;
      });
    }
  }

  Future<void> _handlePayment() async {
    if (_isLoading || !_isAvailable) return;

    setState(() => _isLoading = true);
    widget.onPaymentStarted?.call();

    final result = await applePayService.processPayment(
      bookingId: widget.bookingId,
      amount: widget.amount,
      artistName: widget.artistName,
      serviceName: widget.serviceName,
      serviceFee: widget.serviceFee,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onPaymentComplete?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show on non-iOS platforms
    if (kIsWeb || !Platform.isIOS) {
      return const SizedBox.shrink();
    }

    // Still checking availability
    if (_isChecking) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 50,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    // Not available
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    // Apple Pay button
    return GestureDetector(
      onTap: _isLoading ? null : _handlePayment,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 50,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.apple,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Simple Apple Pay mark/badge
class ApplePayMark extends StatelessWidget {
  final double height;

  const ApplePayMark({
    super.key,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isIOS) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.apple,
            color: Colors.white,
            size: height * 0.7,
          ),
          const SizedBox(width: 2),
          Text(
            'Pay',
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
