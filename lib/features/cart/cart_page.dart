import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/providers/cart_provider.dart';
import 'package:gearsh_app/widgets/bottom_nav_bar.dart';
import 'package:gearsh_app/widgets/gearsh_background.dart';
import 'package:gearsh_app/services/user_role_service.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  // Theme colors
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _red500 = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return GearshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _slate900.withAlpha(230),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              try {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              } catch (e) {
                context.go('/');
              }
            },
          ),
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_sky400, _cyan500],
                ).createShader(bounds),
                child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cart.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _sky500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            if (cart.isNotEmpty)
              TextButton(
                onPressed: () => _showClearCartDialog(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: _red500, fontSize: 14),
                ),
              ),
          ],
        ),
        body: cart.isEmpty
            ? _buildEmptyCart()
            : _buildCartContent(cart),
        bottomNavigationBar: cart.isEmpty
            ? const BottomNavBar()
            : _buildCheckoutBar(cart),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _slate800,
              shape: BoxShape.circle,
              border: Border.all(color: _sky500.withAlpha(51), width: 1),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: _sky400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse artists and add services to your cart',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _sky500.withAlpha(77),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                'Explore Artists',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartState cart) {
    // Group items by artist
    final Map<String, List<CartItem>> groupedItems = {};
    for (final item in cart.items) {
      groupedItems.putIfAbsent(item.artistId, () => []).add(item);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart items grouped by artist
          ...groupedItems.entries.map((entry) =>
            _buildArtistGroup(entry.key, entry.value)
          ),

          const SizedBox(height: 24),

          // Price summary
          _buildPriceSummary(cart),

          const SizedBox(height: 100), // Space for checkout bar
        ],
      ),
    );
  }

  Widget _buildArtistGroup(String artistId, List<CartItem> items) {
    final firstItem = items.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _slate800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky500.withAlpha(51), width: 1),
      ),
      child: Column(
        children: [
          // Artist header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _slate900.withAlpha(128),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage(firstItem.artistImage),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person, color: Colors.white54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.artistName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${items.length} service${items.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/artist/$artistId'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _sky500.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _sky500.withAlpha(51)),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                        color: _sky400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Service items
          ...items.map((item) => _buildCartItem(item)),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _sky500.withAlpha(26), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.serviceDuration.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: _sky400),
                            const SizedBox(width: 4),
                            Text(
                              item.serviceDuration,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.serviceDescription.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          item.serviceDescription,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${item.servicePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _sky400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _removeItem(item),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _red500.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _red500.withAlpha(51)),
                      ),
                      child: const Icon(Icons.delete_outline, color: _red500, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Date/Time/Location if set
          if (item.selectedDate != null || item.location != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _slate900.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (item.selectedDate != null)
                    _buildDetailRow(
                      Icons.calendar_today,
                      '${item.selectedDate!.day}/${item.selectedDate!.month}/${item.selectedDate!.year}${item.selectedTime != null ? ' at ${item.selectedTime}' : ''}',
                    ),
                  if (item.location != null && item.location!.isNotEmpty)
                    _buildDetailRow(Icons.location_on, item.location!),
                ],
              ),
            ),
          // Edit button
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => _editItemDetails(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _sky500.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _sky500.withAlpha(51)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_calendar, size: 16, color: _sky400),
                    const SizedBox(width: 6),
                    Text(
                      item.selectedDate != null ? 'Edit Details' : 'Add Event Details',
                      style: const TextStyle(
                        color: _sky400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _slate800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky500.withAlpha(51), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal (${cart.itemCount} items)', 'R${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildPriceRow('Service Fee (12.6%)', 'R${cart.serviceFee.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: _sky500.withAlpha(51),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'R${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _sky400,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900,
        border: Border(
          top: BorderSide(color: _sky500.withAlpha(51), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'R${cart.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Checkout button
            GestureDetector(
              onTap: () => _proceedToCheckout(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(77),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      'Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(CartItem item) {
    ref.read(cartActionsProvider).removeItem(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.serviceName} removed from cart'),
        backgroundColor: _slate800,
        action: SnackBarAction(
          label: 'Undo',
          textColor: _sky400,
          onPressed: () {
            ref.read(cartActionsProvider).addItem(item);
          },
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _slate800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cart?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartActionsProvider).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: _red500)),
          ),
        ],
      ),
    );
  }

  void _editItemDetails(CartItem item) {
    DateTime selectedDate = item.selectedDate ?? DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = item.selectedTime != null
        ? TimeOfDay(
            hour: int.parse(item.selectedTime!.split(':')[0]),
            minute: int.parse(item.selectedTime!.split(':')[1]),
          )
        : const TimeOfDay(hour: 18, minute: 0);
    final locationController = TextEditingController(text: item.location ?? '');
    final notesController = TextEditingController(text: item.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: _slate900,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _sky500.withAlpha(51), width: 1),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _sky500.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_calendar, color: _sky400, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.serviceName,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date picker
                      _buildInputTile(
                        icon: Icons.calendar_today,
                        label: 'Event Date',
                        value: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _sky500,
                                  surface: _slate800,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Time picker
                      _buildInputTile(
                        icon: Icons.access_time,
                        label: 'Start Time',
                        value: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _sky500,
                                  surface: _slate800,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Location
                      _buildTextInputTile(
                        icon: Icons.location_on,
                        label: 'Event Location',
                        controller: locationController,
                        hint: 'Enter venue address',
                      ),
                      const SizedBox(height: 12),
                      // Notes
                      _buildTextInputTile(
                        icon: Icons.notes,
                        label: 'Additional Notes',
                        controller: notesController,
                        hint: 'Any special requests...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    ref.read(cartActionsProvider).updateItem(
                      item.id,
                      selectedDate: selectedDate,
                      selectedTime: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      location: locationController.text,
                      notes: notesController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _sky500.withAlpha(77),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Save Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _slate800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _sky500.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _sky400, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: _sky400, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    final cart = ref.read(cartProvider);

    // Check if user is logged in
    if (userRoleService.isGuest && !userRoleService.isLoggedIn) {
      _showSignUpPrompt();
      return;
    }

    // Check if all items have event details
    final itemsWithoutDate = cart.items.where((item) => item.selectedDate == null).toList();
    if (itemsWithoutDate.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add event details for ${itemsWithoutDate.length} item${itemsWithoutDate.length > 1 ? 's' : ''}'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Add Now',
            textColor: Colors.white,
            onPressed: () => _editItemDetails(itemsWithoutDate.first),
          ),
        ),
      );
      return;
    }

    // Navigate to cart checkout
    context.go('/cart/checkout');
  }

  void _showSignUpPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _sky500.withAlpha(51), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _sky500.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_checkout, color: _sky400, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign Up to Checkout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create an account to complete your booking and pay securely.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go('/signup');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Sign Up Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: const Text(
                'Already have an account? Log In',
                style: TextStyle(color: _sky400),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

