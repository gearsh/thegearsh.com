// Gearsh Offline Banner Widget
// Shows connectivity status to users

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/offline/connectivity_service.dart';
import 'package:gearsh_app/core/offline/sync_service.dart';

/// Offline banner that shows when the app is offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    // Don't show anything when online and not syncing
    if (connectivityStatus == ConnectivityStatus.online &&
        syncStatus == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: connectivityStatus == ConnectivityStatus.offline ? 36 :
              syncStatus == SyncStatus.syncing ? 36 : 0,
      child: Material(
        color: _getBannerColor(connectivityStatus, syncStatus),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getBannerIcon(connectivityStatus, syncStatus),
                const SizedBox(width: 8),
                Text(
                  _getBannerText(connectivityStatus, syncStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBannerColor(ConnectivityStatus connectivity, SyncStatus sync) {
    if (connectivity == ConnectivityStatus.offline) {
      return Colors.grey.shade700;
    }
    switch (sync) {
      case SyncStatus.syncing:
        return Colors.blue.shade600;
      case SyncStatus.failed:
        return Colors.orange.shade700;
      case SyncStatus.completed:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _getBannerIcon(ConnectivityStatus connectivity, SyncStatus sync) {
    if (connectivity == ConnectivityStatus.offline) {
      return const Icon(Icons.cloud_off, color: Colors.white, size: 18);
    }
    switch (sync) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.failed:
        return const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18);
      case SyncStatus.completed:
        return const Icon(Icons.check_circle_outline, color: Colors.white, size: 18);
      default:
        return const Icon(Icons.cloud_off, color: Colors.white, size: 18);
    }
  }

  String _getBannerText(ConnectivityStatus connectivity, SyncStatus sync) {
    if (connectivity == ConnectivityStatus.offline) {
      return 'You\'re offline - showing cached data';
    }
    switch (sync) {
      case SyncStatus.syncing:
        return 'Syncing changes...';
      case SyncStatus.failed:
        return 'Some changes couldn\'t sync';
      case SyncStatus.completed:
        return 'All changes synced';
      default:
        return '';
    }
  }
}

/// Wrapper widget that shows offline banner at top of screen
class OfflineAwareScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;

  const OfflineAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Widget that shows pending sync count badge
class SyncBadge extends ConsumerWidget {
  final Widget child;

  const SyncBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        pendingCount.when(
          data: (count) {
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Connection status indicator widget
class ConnectionStatusIndicator extends ConsumerWidget {
  final double size;

  const ConnectionStatusIndicator({super.key, this.size = 12});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status == ConnectivityStatus.online
            ? Colors.green
            : status == ConnectivityStatus.offline
                ? Colors.red
                : Colors.orange,
        boxShadow: [
          BoxShadow(
            color: (status == ConnectivityStatus.online
                    ? Colors.green
                    : status == ConnectivityStatus.offline
                        ? Colors.red
                        : Colors.orange)
                .withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

