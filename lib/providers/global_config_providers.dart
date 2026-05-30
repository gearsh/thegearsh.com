// Gearsh Global Configuration Providers
// Riverpod providers for global configuration state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/contracts/i_config_repository.dart';
import 'package:gearsh_app/core/di/service_providers.dart';
import '../services/global_config_service.dart';

/// Provider for the global config service
final globalConfigProvider = Provider<IConfigRepository>((ref) {
  return ref.watch(configRepositoryProvider);
});

/// Provider for current region - watches for changes
final currentRegionProvider = Provider<RegionConfig>((ref) {
  return ref.watch(globalConfigProvider).currentRegion;
});

/// Provider to format prices
final priceFormatterProvider = Provider<String Function(double)>((ref) {
  return ref.watch(globalConfigProvider).formatPrice;
});

/// Provider for short price format
final shortPriceFormatterProvider = Provider<String Function(double)>((ref) {
  return ref.watch(globalConfigProvider).formatPriceShort;
});

/// Provider for available payment methods
final paymentProvidersProvider = Provider<List<String>>((ref) {
  return ref.watch(globalConfigProvider).getPaymentProviders();
});

/// State notifier for region selection
class RegionNotifier extends Notifier<RegionConfig> {
  @override
  RegionConfig build() {
    return ref.watch(globalConfigProvider).currentRegion;
  }

  Future<void> setRegion(RegionConfig region) async {
    state = region;
    await ref.read(globalConfigProvider).setRegion(region);
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

