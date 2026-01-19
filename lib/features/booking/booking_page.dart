import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:gearsh_app/providers/booking_provider.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/widgets/custom_app_bar.dart';

class BookingPage extends ConsumerStatefulWidget {
  final String artistId;
  const BookingPage({required this.artistId, super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking(Artist artist) async {
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an event location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingNotifier = ref.read(bookingProvider.notifier);
      final userId = userRoleService.userEmail.isNotEmpty
          ? userRoleService.userEmail
          : 'guest_user';

      final result = await bookingNotifier.createBooking(
        clientId: userId,
        artistId: artist.id,
        eventDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        eventTime: _selectedTime.format(context),
        eventLocation: _locationController.text.trim(),
        eventType: 'Event Booking',
        durationHours: 2.0,
        totalPrice: (artist.baseRate ?? 0) * 1.05, // Including 5% fee
        notes: _notesController.text.trim(),
      );

      setState(() => _isSubmitting = false);

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking request sent! ID: ${result.bookingId}'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/my-bookings');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to create booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    final fee = instantQuote * 0.05;
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
        _buildFormGroup('Event Location *',
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'Enter venue or address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ),

        // Notes Input
        _buildFormGroup('Additional Notes',
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any special requirements or details...',
            ),
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
              _buildPriceRow('Artist Fee', 'R${instantQuote.toStringAsFixed(0)}', theme),
              const Divider(color: Colors.white30, height: 24),
              _buildPriceRow('Service Fee (5%)', 'R${fee.toStringAsFixed(0)}', theme),
              const Divider(color: Colors.white30, height: 24),
              _buildPriceRow('Total', 'R${total.toStringAsFixed(0)}', theme, isBold: true),
            ],
          ),
        ),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitBooking(artist),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Request to Book'),
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
      child: Row(
        children: [
          Expanded(child: Text(value)),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
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
