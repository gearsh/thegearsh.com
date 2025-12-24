import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/search_models.dart';
import 'package:gearsh_app/providers/search_provider.dart';

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildCategoryFilter(ref, filters),
              const SizedBox(height: 20),
              _buildRatingFilter(ref, filters),
              const SizedBox(height: 20),
              _buildPriceFilter(ref, filters),
              const SizedBox(height: 20),
              _buildVerifiedFilter(ref, filters),
              const SizedBox(height: 20),
              _buildSortBy(ref, filters),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(searchFiltersProvider.notifier).reset(),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(WidgetRef ref, SearchFilters filters) {
    const allCategories = {'DJ', 'Photographer', 'Videographer', 'Host', 'Producer'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8.0,
          children: allCategories.map((category) {
            final isSelected = filters.categories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                final currentCategories = filters.categories.toSet();
                if (selected) {
                  currentCategories.add(category);
                } else {
                  currentCategories.remove(category);
                }
                ref.read(searchFiltersProvider.notifier).setCategories(currentCategories);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter(WidgetRef ref, SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Minimum Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [4.5, 4.0, 3.5, 3.0].map((rating) {
            return ChoiceChip(
              label: Text('$rating+'),
              selected: filters.minRating == rating,
              onSelected: (selected) {
                if (selected) {
                  ref.read(searchFiltersProvider.notifier).setMinRating(rating);
                } else {
                  ref.read(searchFiltersProvider.notifier).setMinRating(0);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter(WidgetRef ref, SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        RangeSlider(
          values: filters.priceRange,
          min: 0,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '\$${filters.priceRange.start.round()}',
            '\$${filters.priceRange.end.round()}',
          ),
          onChanged: (values) {
            ref.read(searchFiltersProvider.notifier).setPriceRange(values);
          },
        ),
      ],
    );
  }

  Widget _buildVerifiedFilter(WidgetRef ref, SearchFilters filters) {
    return SwitchListTile(
      title: const Text('Verified Artists Only', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      value: filters.showVerifiedOnly,
      onChanged: (_) => ref.read(searchFiltersProvider.notifier).toggleVerifiedOnly(),
    );
  }

  Widget _buildSortBy(WidgetRef ref, SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        DropdownButton<SortOption>(
          value: filters.sortOption,
          onChanged: (SortOption? newValue) {
            if (newValue != null) {
              ref.read(searchFiltersProvider.notifier).setSortOption(newValue);
            }
          },
          items: SortOption.values.map((SortOption option) {
            return DropdownMenuItem<SortOption>(
              value: option,
              child: Text(option.toString().split('.').last.replaceAllMapped(
                  RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim()),
            );
          }).toList(),
        ),
      ],
    );
  }
}

