import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingState {
  // TODO: Add properties to represent booking state
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => BookingState();

  // TODO: Add methods to manage booking state
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);
