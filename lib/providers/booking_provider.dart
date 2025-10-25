import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingProvider = StateNotifierProvider((ref) => BookingNotifier());

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(BookingState());

  // TODO: Add methods to manage booking state
}

class BookingState {
  // TODO: Add properties to represent booking state
}
