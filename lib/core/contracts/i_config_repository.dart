import 'package:gearsh_app/services/global_config_service.dart';

/// Locale and currency configuration contract (Dependency Inversion).
abstract class IConfigRepository {
  Future<void> init();
  RegionConfig get currentRegion;
  Future<void> setRegion(RegionConfig region);
  String formatPrice(double priceInLocalCurrency);
  String formatPriceShort(double price);
  List<String> getPaymentProviders();
  String getTermsJurisdiction();
  double convertCurrency(double amount, RegionConfig from, RegionConfig to);
  double calculateServiceFee(double bookingAmount);
  double getTotalWithServiceFee(double bookingAmount);
}
