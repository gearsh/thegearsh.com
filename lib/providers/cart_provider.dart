import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';

/// Cart item representing a service booking
class CartItem {
  final String id;
  final String artistId;
  final String artistName;
  final String artistImage;
  final String serviceId;
  final String serviceName;
  final String serviceDescription;
  final String serviceDuration;
  final double servicePrice;
  final List<String> serviceIncludes;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? location;
  final String? notes;

  CartItem({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.artistImage,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDescription,
    required this.serviceDuration,
    required this.servicePrice,
    required this.serviceIncludes,
    this.selectedDate,
    this.selectedTime,
    this.location,
    this.notes,
  });

  CartItem copyWith({
    DateTime? selectedDate,
    String? selectedTime,
    String? location,
    String? notes,
  }) {
    return CartItem(
      id: id,
      artistId: artistId,
      artistName: artistName,
      artistImage: artistImage,
      serviceId: serviceId,
      serviceName: serviceName,
      serviceDescription: serviceDescription,
      serviceDuration: serviceDuration,
      servicePrice: servicePrice,
      serviceIncludes: serviceIncludes,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  /// Create a cart item from artist and service data
  factory CartItem.fromArtistService(GearshArtist artist, Map<String, dynamic> service) {
    return CartItem(
      id: '${artist.id}-${service['id']}-${DateTime.now().millisecondsSinceEpoch}',
      artistId: artist.id,
      artistName: artist.name,
      artistImage: artist.image,
      serviceId: service['id'] as String,
      serviceName: service['name'] as String,
      serviceDescription: service['description'] as String? ?? '',
      serviceDuration: service['duration'] as String? ?? '',
      servicePrice: (service['price'] as num).toDouble(),
      serviceIncludes: List<String>.from(service['includes'] ?? []),
    );
  }
}

/// Cart state
class CartState {
  final List<CartItem> items;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.isLoading = false,
  });

  int get itemCount => items.length;

  double get subtotal => items.fold(0, (sum, item) => sum + item.servicePrice);

  double get serviceFee => subtotal * 0.126; // 12.6% service fee

  double get total => subtotal + serviceFee;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  /// Check if an artist's service is already in cart
  bool hasItem(String artistId, String serviceId) {
    return items.any((item) => item.artistId == artistId && item.serviceId == serviceId);
  }

  /// Get items for a specific artist
  List<CartItem> getItemsForArtist(String artistId) {
    return items.where((item) => item.artistId == artistId).toList();
  }

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Cart notifier for state management
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Add item to cart
  void addItem(CartItem item) {
    if (state.hasItem(item.artistId, item.serviceId)) {
      return; // Don't add duplicates
    }
    state = state.copyWith(items: [...state.items, item]);
  }

  /// Add item from artist and service
  void addFromArtistService(GearshArtist artist, Map<String, dynamic> service) {
    final item = CartItem.fromArtistService(artist, service);
    addItem(item);
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }

  /// Remove all items for an artist
  void removeArtistItems(String artistId) {
    state = state.copyWith(
      items: state.items.where((item) => item.artistId != artistId).toList(),
    );
  }

  /// Update item details (date, time, location, notes)
  void updateItem(String itemId, {
    DateTime? selectedDate,
    String? selectedTime,
    String? location,
    String? notes,
  }) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            location: location,
            notes: notes,
          );
        }
        return item;
      }).toList(),
    );
  }

  /// Clear entire cart
  void clearCart() {
    state = const CartState();
  }

  /// Check if service is in cart
  bool isInCart(String artistId, String serviceId) {
    return state.hasItem(artistId, serviceId);
  }
}

/// Cart provider using NotifierProvider
final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

/// Cart actions provider (shortcut to notifier)
final cartActionsProvider = Provider<CartNotifier>((ref) {
  return ref.read(cartProvider.notifier);
});

/// Cart item count provider for badge display
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

/// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).total;
});

