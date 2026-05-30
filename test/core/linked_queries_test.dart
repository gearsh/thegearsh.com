import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearsh_app/core/contracts/i_booking_repository.dart';
import 'package:gearsh_app/core/di/service_providers.dart';
import 'package:gearsh_app/core/queries/linked_queries.dart';
import 'package:gearsh_app/services/auth_api_service.dart';
import 'package:gearsh_app/services/booking_service.dart';

class FakeBookingRepository implements IBookingRepository {
  FakeBookingRepository(this.bookings);

  List<Booking> bookings;

  @override
  Future<bool> cancelBooking(String bookingId) async => true;

  @override
  Future<bool> confirmBooking(String bookingId) async => true;

  @override
  Future<bool> completeBooking(String bookingId) async => true;

  @override
  Future<BookingResult> createBooking({
    required String clientId,
    required String artistId,
    String? serviceId,
    required String eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventType,
    double? durationHours,
    required double totalPrice,
    String? notes,
  }) async {
    return BookingResult.success(bookingId: 'new', status: 'pending');
  }

  @override
  Future<List<Booking>> getBookings({
    required String userId,
    String userType = 'client',
    String? status,
  }) async {
    return bookings;
  }
}

void main() {
  test('linked bookings query partitions upcoming and past', () async {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 7)).toIso8601String().split('T').first;
    final pastDate = now.subtract(const Duration(days: 7)).toIso8601String().split('T').first;

    final container = ProviderContainer(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(
          FakeBookingRepository([
            Booking(
              id: '1',
              clientId: 'user-1',
              artistId: 'artist-1',
              eventDate: futureDate,
              totalPrice: 1000,
              status: 'confirmed',
              createdAt: now,
            ),
            Booking(
              id: '2',
              clientId: 'user-1',
              artistId: 'artist-2',
              eventDate: pastDate,
              totalPrice: 500,
              status: 'completed',
              createdAt: now,
            ),
          ]),
        ),
        currentUserProvider.overrideWith(() => _FakeCurrentUserNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final partition = await container.read(userBookingsPartitionProvider.future);

    expect(partition.upcoming.length, 1);
    expect(partition.past.length, 1);
    expect(partition.upcoming.first.id, '1');
    expect(partition.past.first.id, '2');
  });

  test('session revision invalidates linked booking query', () async {
    final repo = FakeBookingRepository([]);
    final container = ProviderContainer(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith(() => _FakeCurrentUserNotifier()),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(userBookingsLinkedQueryProvider.future), isEmpty);

    repo.bookings = [
      Booking(
        id: '99',
        clientId: 'user-1',
        artistId: 'artist-1',
        eventDate: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first,
        totalPrice: 2500,
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    ];

    container.invalidate(userBookingsLinkedQueryProvider);
    container.invalidate(userBookingsPartitionProvider);
    final bookings = await container.read(userBookingsLinkedQueryProvider.future);
    expect(bookings.length, 1);
    expect(bookings.first.id, '99');
  });
}

class _FakeCurrentUserNotifier extends CurrentUserNotifier {
  @override
  AuthUser? build() {
    return AuthUser(
      userId: 'user-1',
      email: 'test@gearsh.com',
      userType: 'client',
      firstName: 'Test',
      lastName: 'User',
      token: 'token',
    );
  }
}
