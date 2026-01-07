// Gearsh Global Configuration Service
// Manages internationalization, currency, and locale settings

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported regions with their configurations
class RegionConfig {
  final String code;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String locale;
  final String flag;
  final String phoneCode;
  final double exchangeRateToUSD; // Base rate for conversions

  const RegionConfig({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.locale,
    required this.flag,
    required this.phoneCode,
    required this.exchangeRateToUSD,
  });
}

/// All supported regions
class SupportedRegions {
  static const RegionConfig southAfrica = RegionConfig(
    code: 'ZA',
    name: 'South Africa',
    currencyCode: 'ZAR',
    currencySymbol: 'R',
    locale: 'en_ZA',
    flag: '🇿🇦',
    phoneCode: '+27',
    exchangeRateToUSD: 18.5,
  );

  static const RegionConfig unitedStates = RegionConfig(
    code: 'US',
    name: 'United States',
    currencyCode: 'USD',
    currencySymbol: '\$',
    locale: 'en_US',
    flag: '🇺🇸',
    phoneCode: '+1',
    exchangeRateToUSD: 1.0,
  );

  static const RegionConfig unitedKingdom = RegionConfig(
    code: 'GB',
    name: 'United Kingdom',
    currencyCode: 'GBP',
    currencySymbol: '£',
    locale: 'en_GB',
    flag: '🇬🇧',
    phoneCode: '+44',
    exchangeRateToUSD: 0.79,
  );

  static const RegionConfig nigeria = RegionConfig(
    code: 'NG',
    name: 'Nigeria',
    currencyCode: 'NGN',
    currencySymbol: '₦',
    locale: 'en_NG',
    flag: '🇳🇬',
    phoneCode: '+234',
    exchangeRateToUSD: 1550.0,
  );

  static const RegionConfig kenya = RegionConfig(
    code: 'KE',
    name: 'Kenya',
    currencyCode: 'KES',
    currencySymbol: 'KSh',
    locale: 'en_KE',
    flag: '🇰🇪',
    phoneCode: '+254',
    exchangeRateToUSD: 153.0,
  );

  static const RegionConfig ghana = RegionConfig(
    code: 'GH',
    name: 'Ghana',
    currencyCode: 'GHS',
    currencySymbol: 'GH₵',
    locale: 'en_GH',
    flag: '🇬🇭',
    phoneCode: '+233',
    exchangeRateToUSD: 15.5,
  );

  static const RegionConfig australia = RegionConfig(
    code: 'AU',
    name: 'Australia',
    currencyCode: 'AUD',
    currencySymbol: 'A\$',
    locale: 'en_AU',
    flag: '🇦🇺',
    phoneCode: '+61',
    exchangeRateToUSD: 1.53,
  );

  static const RegionConfig canada = RegionConfig(
    code: 'CA',
    name: 'Canada',
    currencyCode: 'CAD',
    currencySymbol: 'C\$',
    locale: 'en_CA',
    flag: '🇨🇦',
    phoneCode: '+1',
    exchangeRateToUSD: 1.36,
  );

  static const RegionConfig germany = RegionConfig(
    code: 'DE',
    name: 'Germany',
    currencyCode: 'EUR',
    currencySymbol: '€',
    locale: 'de_DE',
    flag: '🇩🇪',
    phoneCode: '+49',
    exchangeRateToUSD: 0.92,
  );

  static const RegionConfig france = RegionConfig(
    code: 'FR',
    name: 'France',
    currencyCode: 'EUR',
    currencySymbol: '€',
    locale: 'fr_FR',
    flag: '🇫🇷',
    phoneCode: '+33',
    exchangeRateToUSD: 0.92,
  );

  static const RegionConfig brazil = RegionConfig(
    code: 'BR',
    name: 'Brazil',
    currencyCode: 'BRL',
    currencySymbol: 'R\$',
    locale: 'pt_BR',
    flag: '🇧🇷',
    phoneCode: '+55',
    exchangeRateToUSD: 4.97,
  );

  static const RegionConfig india = RegionConfig(
    code: 'IN',
    name: 'India',
    currencyCode: 'INR',
    currencySymbol: '₹',
    locale: 'en_IN',
    flag: '🇮🇳',
    phoneCode: '+91',
    exchangeRateToUSD: 83.0,
  );

  static const RegionConfig uae = RegionConfig(
    code: 'AE',
    name: 'United Arab Emirates',
    currencyCode: 'AED',
    currencySymbol: 'د.إ',
    locale: 'ar_AE',
    flag: '🇦🇪',
    phoneCode: '+971',
    exchangeRateToUSD: 3.67,
  );

  static const RegionConfig japan = RegionConfig(
    code: 'JP',
    name: 'Japan',
    currencyCode: 'JPY',
    currencySymbol: '¥',
    locale: 'ja_JP',
    flag: '🇯🇵',
    phoneCode: '+81',
    exchangeRateToUSD: 149.0,
  );

  static const RegionConfig botswana = RegionConfig(
    code: 'BW',
    name: 'Botswana',
    currencyCode: 'BWP',
    currencySymbol: 'P',
    locale: 'en_BW',
    flag: '🇧🇼',
    phoneCode: '+267',
    exchangeRateToUSD: 13.5,
  );

  static const RegionConfig namibia = RegionConfig(
    code: 'NA',
    name: 'Namibia',
    currencyCode: 'NAD',
    currencySymbol: 'N\$',
    locale: 'en_NA',
    flag: '🇳🇦',
    phoneCode: '+264',
    exchangeRateToUSD: 18.5,
  );

  static const RegionConfig zimbabwe = RegionConfig(
    code: 'ZW',
    name: 'Zimbabwe',
    currencyCode: 'USD',
    currencySymbol: '\$',
    locale: 'en_ZW',
    flag: '🇿🇼',
    phoneCode: '+263',
    exchangeRateToUSD: 1.0,
  );

  static const RegionConfig tanzania = RegionConfig(
    code: 'TZ',
    name: 'Tanzania',
    currencyCode: 'TZS',
    currencySymbol: 'TSh',
    locale: 'sw_TZ',
    flag: '🇹🇿',
    phoneCode: '+255',
    exchangeRateToUSD: 2500.0,
  );

  static const RegionConfig uganda = RegionConfig(
    code: 'UG',
    name: 'Uganda',
    currencyCode: 'UGX',
    currencySymbol: 'USh',
    locale: 'en_UG',
    flag: '🇺🇬',
    phoneCode: '+256',
    exchangeRateToUSD: 3750.0,
  );

  static const RegionConfig rwanda = RegionConfig(
    code: 'RW',
    name: 'Rwanda',
    currencyCode: 'RWF',
    currencySymbol: 'FRw',
    locale: 'rw_RW',
    flag: '🇷🇼',
    phoneCode: '+250',
    exchangeRateToUSD: 1250.0,
  );

  /// List of all supported regions
  static const List<RegionConfig> all = [
    southAfrica,
    unitedStates,
    unitedKingdom,
    nigeria,
    kenya,
    ghana,
    australia,
    canada,
    germany,
    france,
    brazil,
    india,
    uae,
    japan,
    botswana,
    namibia,
    zimbabwe,
    tanzania,
    uganda,
    rwanda,
  ];

  /// Get region by code
  static RegionConfig? getByCode(String code) {
    try {
      return all.firstWhere((r) => r.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Africa regions for quick access
  static const List<RegionConfig> africa = [
    southAfrica,
    nigeria,
    kenya,
    ghana,
    botswana,
    namibia,
    zimbabwe,
    tanzania,
    uganda,
    rwanda,
  ];

  /// Europe regions
  static const List<RegionConfig> europe = [
    unitedKingdom,
    germany,
    france,
  ];

  /// Americas
  static const List<RegionConfig> americas = [
    unitedStates,
    canada,
    brazil,
  ];

  /// Asia Pacific
  static const List<RegionConfig> asiaPacific = [
    australia,
    india,
    uae,
    japan,
  ];
}

/// Global configuration service singleton
class GlobalConfigService extends ChangeNotifier {
  static final GlobalConfigService _instance = GlobalConfigService._internal();
  factory GlobalConfigService() => _instance;
  GlobalConfigService._internal();

  // Current region configuration
  RegionConfig _currentRegion = SupportedRegions.southAfrica;
  RegionConfig get currentRegion => _currentRegion;

  // Stored prices are in USD for consistency
  static const double _baseServiceFeePercent = 0.126; // 12.6% service fee

  /// Initialise from stored preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final regionCode = prefs.getString('region_code') ?? 'ZA';
    _currentRegion = SupportedRegions.getByCode(regionCode) ?? SupportedRegions.southAfrica;
    notifyListeners();
  }

  /// Set current region
  Future<void> setRegion(RegionConfig region) async {
    _currentRegion = region;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('region_code', region.code);
    notifyListeners();
  }

  /// Format price in current currency
  String formatPrice(double priceInLocalCurrency) {
    final formatter = NumberFormat.currency(
      locale: _currentRegion.locale,
      symbol: _currentRegion.currencySymbol,
      decimalDigits: priceInLocalCurrency >= 1000 ? 0 : 2,
    );
    return formatter.format(priceInLocalCurrency);
  }

  /// Format price with short notation (e.g., R87k)
  String formatPriceShort(double price) {
    if (price >= 1000000) {
      return '${_currentRegion.currencySymbol}${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${_currentRegion.currencySymbol}${(price / 1000).toStringAsFixed(0)}k';
    }
    return '${_currentRegion.currencySymbol}${price.toStringAsFixed(0)}';
  }

  /// Convert price from USD to current currency
  double convertFromUSD(double usdAmount) {
    return usdAmount * _currentRegion.exchangeRateToUSD;
  }

  /// Convert price from current currency to USD
  double convertToUSD(double localAmount) {
    return localAmount / _currentRegion.exchangeRateToUSD;
  }

  /// Convert between any two currencies
  double convertCurrency(double amount, RegionConfig from, RegionConfig to) {
    final usdAmount = amount / from.exchangeRateToUSD;
    return usdAmount * to.exchangeRateToUSD;
  }

  /// Calculate service fee
  double calculateServiceFee(double bookingAmount) {
    return bookingAmount * _baseServiceFeePercent;
  }

  /// Get total with service fee
  double getTotalWithServiceFee(double bookingAmount) {
    return bookingAmount + calculateServiceFee(bookingAmount);
  }

  /// Get formatted location based on region
  String formatLocation(String city, String? countryCode) {
    if (countryCode == null) return city;
    final region = SupportedRegions.getByCode(countryCode);
    if (region != null) {
      return '$city, ${region.code}';
    }
    return city;
  }

  /// Check if region is supported
  bool isRegionSupported(String code) {
    return SupportedRegions.getByCode(code) != null;
  }

  /// Get appropriate payment providers for region
  List<String> getPaymentProviders() {
    switch (_currentRegion.code) {
      case 'ZA':
        return ['PayFast', 'PayStack', 'Card'];
      case 'NG':
      case 'GH':
      case 'KE':
        return ['Flutterwave', 'PayStack', 'M-Pesa'];
      case 'US':
      case 'CA':
        return ['Stripe', 'PayPal', 'Card'];
      case 'GB':
      case 'DE':
      case 'FR':
        return ['Stripe', 'PayPal', 'Card'];
      case 'AU':
        return ['Stripe', 'PayPal', 'Card'];
      case 'IN':
        return ['Razorpay', 'PayTM', 'UPI'];
      case 'AE':
        return ['Stripe', 'PayTabs', 'Card'];
      case 'BR':
        return ['PagSeguro', 'MercadoPago', 'PIX'];
      default:
        return ['Flutterwave', 'PayPal', 'Card'];
    }
  }

  /// Get terms jurisdiction based on region
  String getTermsJurisdiction() {
    switch (_currentRegion.code) {
      case 'ZA':
        return 'South Africa';
      case 'US':
        return 'the State of Delaware, United States';
      case 'GB':
        return 'England and Wales';
      case 'AU':
        return 'New South Wales, Australia';
      default:
        return 'the jurisdiction where Gearsh operates';
    }
  }
}

/// Singleton instance
final globalConfigService = GlobalConfigService();

