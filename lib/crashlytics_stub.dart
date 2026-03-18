class FirebaseCrashlytics {
  static final FirebaseCrashlytics instance = FirebaseCrashlytics._();
  FirebaseCrashlytics._();
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}
  void recordFlutterFatalError(dynamic errorDetails) {}
  Future<void> recordError(dynamic error, dynamic stack, {bool fatal = false}) async {}
}
