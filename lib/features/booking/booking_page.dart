import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:gearsh_app/widgets/custom_app_bar.dart';

class BookingPage extends ConsumerStatefulWidget {
  final String artistId;
  const BookingPage({required this.artistId, super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  final TextEditingController _locationController = TextEditingController(text: '450 Elm St');

  @override
  Widget build(BuildContext context) {
    final artistAsync = ref.watch(artistByIdProvider(widget.artistId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Book Artist'),
      body: artistAsync.when(
        data: (artist) {
          if (artist == null) {
            return const Center(child: Text('Artist not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist.name, style: theme.textTheme.displaySmall),
                Text(artist.category ?? 'N/A', style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor)),
                const SizedBox(height: 32),
                _buildBookingForm(context, theme, artist),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildBookingForm(BuildContext context, ThemeData theme, Artist artist) {
    final instantQuote = artist.baseRate ?? 0;
    final fee = instantQuote * 0.05; // Example 5% fee
    final total = instantQuote + fee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Picker
        _buildFormGroup('Date', 
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: _buildFormInput(DateFormat.yMMMMd().format(_selectedDate)),
          ),
        ),

        // Time Picker
        _buildFormGroup('Start Time', 
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            child: _buildFormInput(_selectedTime.format(context)),
          ),
        ),

        // Location Input
        _buildFormGroup('Location', 
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(hintText: 'Enter location'),
          ),
        ),
        
        // Price Summary
        Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPriceRow('Instant Quote', NumberFormat.simpleCurrency(locale: 'en_US').format(instantQuote), theme),
              const Divider(color: Colors.white30, height: 24),
              _buildPriceRow('Service Fee', NumberFormat.simpleCurrency(locale: 'en_US').format(fee), theme),
              const Divider(color: Colors.white30, height: 24),
              _buildPriceRow('Total', NumberFormat.simpleCurrency(locale: 'en_US').format(total), theme, isBold: true),
            ],
          ),
        ),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement contract generation and booking submission
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking request sent!')),
              );
              context.go('/profile/${artist.id}');
            },
            child: const Text('Request to Book'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormGroup(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildFormInput(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: Text(value),
    );
  }

  Widget _buildPriceRow(String label, String value, ThemeData theme, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
