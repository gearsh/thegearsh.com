import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/widgets/custom_app_bar.dart';

class ArtistDashboardPage extends ConsumerWidget {
  const ArtistDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistByIdProvider('1')); // Using DJ Khalid for demo
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Artist Dashboard',
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
              Tab(icon: Icon(Icons.show_chart), text: 'Earnings'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
            ],
          ),
        ),
        body: artistAsync.when(
          data: (artist) {
            if (artist == null) {
              return const Center(child: Text('Artist not found'));
            }
            return TabBarView(
              children: [
                _CalendarTab(artist: artist),
                _EarningsTab(artist: artist),
                _ProfileTab(artist: artist),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  final Artist artist;
  const _CalendarTab({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mock events for demonstration
    final events = {
      DateTime.utc(2024, 7, 10): ['Gig at The Venue'],
      DateTime.utc(2024, 7, 15): ['Private Party'],
      DateTime.utc(2024, 7, 22): ['Corporate Event'],
    };

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: DateTime.now(),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.primaryColor.withAlpha(128),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
      ),
      eventLoader: (day) {
        return events[day] ?? [];
      },
    );
  }
}

class _EarningsTab extends StatelessWidget {
  final Artist artist;
  const _EarningsTab({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Earnings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3), FlSpot(1, 1), FlSpot(2, 4), FlSpot(3, 2), FlSpot(4, 5),
                    ],
                    isCurved: true,
                    color: theme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.primaryColor.withAlpha(77),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Artist artist;
  const _ProfileTab({required this.artist});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(initialValue: artist.name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 16),
          TextFormField(initialValue: artist.bio, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 5),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, child: const Text('Save Changes')),
        ],
      ),
    );
  }
}
