// lib/features/booking/booking_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  final String artistId;
  const BookingPage({required this.artistId, super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  final TextEditingController _locationController = TextEditingController(text: '450 Elm St');

  @override
  Widget build(BuildContext context) {
    final artistName = widget.artistId == 'ava' ? 'Ava Johnson' : 'Ethan Woods';
    final genre = widget.artistId == 'ava' ? 'DJ' : 'Indie';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text('Book Artist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 24),

                // Artist Info
                Column(
                  children: [
                    Text(artistName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(genre, style: const TextStyle(color: Colors.cyanAccent)),
                  ],
                ),
                const SizedBox(height: 24),

                // Date Picker
                FormGroup(
                  label: 'Date',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: FormInput(
                      value: DateFormat.yMMMMd().format(_selectedDate),
                    ),
                  ),
                ),

                // Time Picker
                FormGroup(
                  label: 'Start Time',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                    child: FormInput(
                      value: _selectedTime.format(context),
                    ),
                  ),
                ),

                // Location Input
                FormGroup(
                  label: 'Location',
                  child: TextField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      hintText: 'Enter location',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),

                // Price Summary
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      PriceRow(label: 'Instant Quote', value: '\$800'),
                      Divider(color: Colors.white30, height: 24),
                      PriceRow(label: 'Total', value: '\$815', isBold: true),
                    ],
                  ),
                ),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking submitted!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Form Group Wrapper
class FormGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const FormGroup({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// Form Input Display
class FormInput extends StatelessWidget {
  final String value;
  const FormInput({required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(value, style: const TextStyle(color: Colors.white)),
    );
  }
}

// Price Row
class PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const PriceRow({required this.label, required this.value, this.isBold = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: Colors.cyanAccent, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}