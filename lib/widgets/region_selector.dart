// Region Selector Widget
// Allows users to select their region/country for currency and locale

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/global_config_providers.dart';
import '../services/global_config_service.dart';

class RegionSelectorWidget extends ConsumerWidget {
  const RegionSelectorWidget({super.key});

  static const Color _sky500 = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRegion = ref.watch(currentRegionProvider);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _sky500.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          currentRegion.flag,
          style: const TextStyle(fontSize: 24),
        ),
      ),
      title: const Text(
        'Region & Currency',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${currentRegion.name} (${currentRegion.currencyCode})',
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: () => _showRegionPicker(context, ref),
    );
  }

  void _showRegionPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RegionPickerSheet(ref: ref),
    );
  }
}

class _RegionPickerSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _RegionPickerSheet({required this.ref});

  @override
  ConsumerState<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends ConsumerState<_RegionPickerSheet> {
  String _searchQuery = '';

  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final currentRegion = ref.watch(currentRegionProvider);
    final allRegions = ref.watch(supportedRegionsProvider);

    // Filter regions based on search
    final filteredRegions = _searchQuery.isEmpty
        ? allRegions
        : allRegions.where((r) =>
            r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.currencyCode.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    // Group by continent
    final grouped = <String, List<RegionConfig>>{};
    for (final region in filteredRegions) {
      String continent;
      if (SupportedRegions.africa.contains(region)) {
        continent = 'Africa';
      } else if (SupportedRegions.europe.contains(region)) {
        continent = 'Europe';
      } else if (SupportedRegions.americas.contains(region)) {
        continent = 'Americas';
      } else {
        continent = 'Asia Pacific';
      }
      grouped.putIfAbsent(continent, () => []).add(region);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Select Your Region',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This sets your currency and local preferences',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: _slate800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search countries...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Region list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: _sky400,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ...entry.value.map((region) => _buildRegionTile(region, currentRegion)),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionTile(RegionConfig region, RegionConfig currentRegion) {
    final isSelected = region.code == currentRegion.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? _sky500.withAlpha(26) : _slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _sky500 : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Text(
          region.flag,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          region.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${region.currencySymbol} ${region.currencyCode}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: _sky500)
            : null,
        onTap: () {
          ref.read(regionNotifierProvider.notifier).setRegion(region);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Compact region indicator for app bar or header
class RegionIndicator extends ConsumerWidget {
  final VoidCallback? onTap;

  const RegionIndicator({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRegion = ref.watch(currentRegionProvider);

    return GestureDetector(
      onTap: onTap ?? () => _showQuickPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(51)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentRegion.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              currentRegion.currencyCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  void _showQuickPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RegionPickerSheet(ref: ref),
    );
  }
}

