// Gearsh Connectivity Service
// Monitors network connectivity and manages online/offline state

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  checking,
}

/// Provider for connectivity status
final connectivityStatusProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

/// Provider to check if currently online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status == ConnectivityStatus.online;
});

/// Connectivity state notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  Timer? _checkTimer;
  bool _isChecking = false;

  ConnectivityNotifier() : super(ConnectivityStatus.checking) {
    _startMonitoring();
  }

  void _startMonitoring() {
    // Initial check
    checkConnectivity();

    // Periodic check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectivity();
    });
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    if (_isChecking) return state == ConnectivityStatus.online;

    _isChecking = true;

    try {
      // For web platform, use a simple approach
      if (kIsWeb) {
        state = ConnectivityStatus.online;
        _isChecking = false;
        return true;
      }

      // Try to reach a reliable endpoint
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (state != ConnectivityStatus.online) {
          state = ConnectivityStatus.online;
          debugPrint('📶 Network: Online');
        }
        _isChecking = false;
        return true;
      }
    } on SocketException catch (_) {
      // No internet connection
    } on TimeoutException catch (_) {
      // Connection timeout
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }

    if (state != ConnectivityStatus.offline) {
      state = ConnectivityStatus.offline;
      debugPrint('📵 Network: Offline');
    }

    _isChecking = false;
    return false;
  }

  /// Force online status (for testing)
  void setOnline() {
    state = ConnectivityStatus.online;
  }

  /// Force offline status (for testing)
  void setOffline() {
    state = ConnectivityStatus.offline;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Connectivity-aware operation wrapper
class ConnectivityAwareOperation<T> {
  final Future<T> Function() onlineOperation;
  final Future<T> Function() offlineOperation;
  final Future<T> Function(T onlineResult)? onSyncComplete;

  ConnectivityAwareOperation({
    required this.onlineOperation,
    required this.offlineOperation,
    this.onSyncComplete,
  });

  /// Execute the operation based on connectivity status
  Future<T> execute(bool isOnline) async {
    if (isOnline) {
      try {
        final result = await onlineOperation();
        if (onSyncComplete != null) {
          return await onSyncComplete!(result);
        }
        return result;
      } catch (e) {
        // Fallback to offline operation on network error
        debugPrint('Online operation failed, falling back to offline: $e');
        return offlineOperation();
      }
    } else {
      return offlineOperation();
    }
  }
}

/// Mixin for connectivity-aware widgets/providers
mixin ConnectivityAwareMixin {
  bool _lastKnownOnlineStatus = true;

  bool get isOnline => _lastKnownOnlineStatus;

  void updateConnectivityStatus(bool isOnline) {
    _lastKnownOnlineStatus = isOnline;
  }
}

