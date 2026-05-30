import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/di/service_providers.dart';
import 'package:gearsh_app/core/queries/query_keys.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart' show artistListProvider;
import 'package:gearsh_app/services/auth_api_service.dart';
import 'package:gearsh_app/services/booking_service.dart';
import 'package:gearsh_app/services/messages_service.dart';

/// Linked query: session → message conversations.
final conversationsLinkedQueryProvider =
    FutureProvider<List<MessageConversation>>((ref) async {
  ref.watch(sessionRevisionProvider);

  final session = await ref.watch(appSessionProvider.future);
  if (session == null) return [];

  final repo = ref.watch(messagesRepositoryProvider);
  return repo.fetchConversations();
});

/// Linked query: booking → chat thread.
final chatMessagesLinkedQueryProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, bookingId) async {
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.fetchMessages(bookingId);
});

/// Linked query: session → artist dashboard stats.
final artistDashboardLinkedQueryProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(sessionRevisionProvider);

  final session = await ref.watch(appSessionProvider.future);
  if (session == null) return null;

  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchDashboard();
});

/// Linked query: auth state → restored API session.
final appSessionProvider = FutureProvider<AuthUser?>((ref) async {
  ref.watch(sessionRevisionProvider);

  final cachedUser = ref.watch(currentUserProvider);
  if (cachedUser != null) return cachedUser;

  final authApi = ref.watch(authApiServiceProvider);
  return authApi.restoreSession();
});

/// Linked query: session → bookings list (auto-refetches when session changes).
final userBookingsLinkedQueryProvider = FutureProvider<List<Booking>>((ref) async {
  ref.watch(sessionRevisionProvider);

  final session = await ref.watch(appSessionProvider.future);
  if (session == null) return [];

  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookings(userId: session.userId);
});

class UserBookingsPartition {
  final List<Booking> upcoming;
  final List<Booking> past;

  const UserBookingsPartition({
    required this.upcoming,
    required this.past,
  });

  static const empty = UserBookingsPartition(upcoming: [], past: []);
}

UserBookingsPartition partitionBookings(List<Booking> bookings) {
  final now = DateTime.now();
  final upcoming = <Booking>[];
  final past = <Booking>[];

  for (final booking in bookings) {
    final eventDate = DateTime.tryParse(booking.eventDate);
    final isPast = booking.status == 'completed' ||
        booking.status == 'cancelled' ||
        (eventDate != null && eventDate.isBefore(now));
    if (isPast) {
      past.add(booking);
    } else {
      upcoming.add(booking);
    }
  }

  return UserBookingsPartition(upcoming: upcoming, past: past);
}

/// Linked query: bookings → upcoming / past tabs.
final userBookingsPartitionProvider =
    FutureProvider<UserBookingsPartition>((ref) async {
  final bookings = await ref.watch(userBookingsLinkedQueryProvider.future);
  return partitionBookings(bookings);
});

/// Linked query: artist catalog → single artist detail.
final artistDetailLinkedQueryProvider =
    FutureProvider.family<Artist?, String>((ref, artistId) async {
  final artists = await ref.watch(artistListProvider.future);
  try {
    return artists.firstWhere((artist) => artist.id == artistId);
  } catch (_) {
    return null;
  }
});

/// Invalidate linked booking cache after mutations (create/cancel/confirm).
void invalidateBookingQueries(dynamic ref) {
  ref.invalidate(userBookingsLinkedQueryProvider);
  ref.invalidate(userBookingsPartitionProvider);
}

void invalidateMessagesQueries(dynamic ref) {
  ref.invalidate(conversationsLinkedQueryProvider);
}

void invalidateChatQueries(dynamic ref, String bookingId) {
  ref.invalidate(chatMessagesLinkedQueryProvider(bookingId));
  ref.invalidate(conversationsLinkedQueryProvider);
}

void invalidateDashboardQueries(dynamic ref) {
  ref.invalidate(artistDashboardLinkedQueryProvider);
}

/// Invalidate session-linked data on auth changes.
void invalidateSessionQueries(dynamic ref) {
  ref.read(sessionRevisionProvider.notifier).bump();
  ref.invalidate(appSessionProvider);
  invalidateBookingQueries(ref);
  invalidateMessagesQueries(ref);
  invalidateDashboardQueries(ref);
}

/// Query key registry for debugging and future cache layers.
Object queryProviderForKey(String key, [String? id]) {
  switch (key) {
    case QueryKeys.session:
      return appSessionProvider;
    case QueryKeys.bookings:
      return userBookingsLinkedQueryProvider;
    case QueryKeys.conversations:
      return conversationsLinkedQueryProvider;
    case QueryKeys.chatMessages:
      if (id == null) {
        throw ArgumentError('chat-messages requires a booking id');
      }
      return chatMessagesLinkedQueryProvider(id);
    case QueryKeys.dashboard:
      return artistDashboardLinkedQueryProvider;
    case QueryKeys.artists:
      return artistListProvider;
    case QueryKeys.artistDetail:
      if (id == null) {
        throw ArgumentError('artist-detail requires an id');
      }
      return artistDetailLinkedQueryProvider(id);
    default:
      throw ArgumentError('Unknown query key: $key');
  }
}
