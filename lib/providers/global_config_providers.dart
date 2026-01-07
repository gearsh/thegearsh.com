// Gearsh Global Configuration Providers
// Riverpod providers for global configuration state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/global_config_service.dart';

/// Provider for the global config service
/// Using a simple Provider that returns the singleton
final globalConfigProvider = Provider<GlobalConfigService>((ref) {
  return globalConfigService;
});

/// Provider for current region - watches for changes
final currentRegionProvider = Provider<RegionConfig>((ref) {
  return globalConfigService.currentRegion;
});

/// Provider to format prices
final priceFormatterProvider = Provider<String Function(double)>((ref) {
  return globalConfigService.formatPrice;
});

/// Provider for short price format
final shortPriceFormatterProvider = Provider<String Function(double)>((ref) {
  return globalConfigService.formatPriceShort;
});

/// Provider for available payment methods
final paymentProvidersProvider = Provider<List<String>>((ref) {
  return globalConfigService.getPaymentProviders();
});

/// State notifier for region selection
class RegionNotifier extends Notifier<RegionConfig> {
  @override
  RegionConfig build() {
    return globalConfigService.currentRegion;
  }

  void setRegion(RegionConfig region) {
    state = region;
    globalConfigService.setRegion(region);
  }
}

final regionNotifierProvider = NotifierProvider<RegionNotifier, RegionConfig>(() {
  return RegionNotifier();
});

/// Provider for all supported regions
final supportedRegionsProvider = Provider<List<RegionConfig>>((ref) {
  return SupportedRegions.all;
});

/// Provider for African regions
final africanRegionsProvider = Provider<List<RegionConfig>>((ref) {
  return SupportedRegions.africa;
});

