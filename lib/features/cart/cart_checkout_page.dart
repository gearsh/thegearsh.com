import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/providers/cart_provider.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/services/payfast_service.dart';
import 'package:gearsh_app/widgets/gearsh_background.dart';
import 'package:gearsh_app/widgets/premium_components.dart';

class CartCheckoutPage extends ConsumerStatefulWidget {
  const CartCheckoutPage({super.key});

  @override
  ConsumerState<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends ConsumerState<CartCheckoutPage>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return GearshBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: EmptyStateWidget(
            icon: Icons.shopping_cart_outlined,
            title: 'Your cart is empty',
            subtitle: 'Browse our amazing artists and add services to get started.',
            buttonText: 'Explore Artists',
            onButtonPressed: () => context.go('/'),
          ),
        ),
      );
    }

    return GearshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium App Bar
              SliverAppBar(
                backgroundColor: GearshColors.slate900.withAlpha(230),
                elevation: 0,
                pinned: true,
                expandedHeight: 120,
                leading: _buildBackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          GearshColors.sky500.withAlpha(26),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        'Order Summary',
                        subtitle: '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: 16),

                      // Items list with staggered animation
                      ...List.generate(cart.items.length, (index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildOrderItem(cart.items[index]),
                        );
                      }),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Payment Method'),
                      const SizedBox(height: 12),
                      _buildPaymentMethod(),
                      const SizedBox(height: 24),
                      _buildPriceBreakdown(cart),
                      const SizedBox(height: 24),
                      _buildSecurityNotice(),
                      const SizedBox(height: 16),
                      _buildTerms(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildPayButton(cart),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        try {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/cart');
          }
        } catch (e) {
          context.go('/cart');
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: GearshColors.slate800.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GearshColors.sky500.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: GearshColors.sky400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GearshColors.sky500.withAlpha(77), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: GearshColors.slate700,
              backgroundImage: AssetImage(item.artistImage),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.person, color: Colors.white54, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.artistName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: GearshColors.sky500.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: GearshColors.sky400, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.serviceName,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                if (item.selectedDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: GearshColors.slate900.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event, size: 14, color: GearshColors.cyan400),
                        const SizedBox(width: 6),
                        Text(
                          '${item.selectedDate!.day}/${item.selectedDate!.month}/${item.selectedDate!.year}',
                          style: const TextStyle(color: GearshColors.cyan400, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        if (item.selectedTime != null) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 1,
                            height: 12,
                            color: GearshColors.slate600,
                          ),
                          const Icon(Icons.schedule, size: 14, color: GearshColors.cyan400),
                          const SizedBox(width: 6),
                          Text(
                            item.selectedTime!,
                            style: const TextStyle(color: GearshColors.cyan400, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
                  color: GearshColors.sky400,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text('per booking', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return PremiumCard(
      isSelected: true,
      padding: const EdgeInsets.all(16),
      onTap: () => HapticFeedback.selectionClick(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.payment_rounded, color: GearshColors.sky500, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('PayFast', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.shield, color: GearshColors.green400, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Pay securely with card, EFT, or SnapScan', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(gradient: GearshColors.primaryGradient, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(CartState cart) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: GearshColors.sky400, size: 20),
              SizedBox(width: 10),
              Text('Price Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...cart.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: Text(item.artistName, style: TextStyle(color: Colors.grey[400], fontSize: 14), overflow: TextOverflow.ellipsis)),
                Text('R${item.servicePrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          )),
          _buildDivider(),
          _buildPriceRow('Subtotal', 'R${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Service fee', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _showServiceFeeInfo,
                child: Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
              ),
              const Spacer(),
              Text('R${cart.serviceFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          _buildDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              AnimatedCounter(
                value: cart.total,
                prefix: 'R',
                style: const TextStyle(color: GearshColors.sky400, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent, GearshColors.sky500.withAlpha(77), Colors.transparent]),
      ),
    );
  }

  void _showServiceFeeInfo() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: GearshColors.slate900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('About Service Fees', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'The 12.6% service fee helps us:\n\n• Provide 24/7 customer support\n• Secure payment processing\n• Verify and vet all artists\n• Handle booking disputes\n• Maintain platform security',
              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            PremiumButton(text: 'Got it', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [GearshColors.green500.withAlpha(26), GearshColors.green500.withAlpha(13)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GearshColors.green500.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: GearshColors.green500.withAlpha(38), shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: GearshColors.green400, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Secure Payment', style: TextStyle(color: GearshColors.green400, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Your payment is protected with bank-level encryption.', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerms() {
    return Text.rich(
      TextSpan(
        style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5),
        children: const [
          TextSpan(text: 'By completing this payment, you agree to our '),
          TextSpan(text: 'Terms of Service', style: TextStyle(color: GearshColors.sky400, fontWeight: FontWeight.w500)),
          TextSpan(text: '. Payments will be held securely until artists confirm your bookings.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPayButton(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GearshColors.slate950, GearshColors.slate900]),
        border: Border(top: BorderSide(color: GearshColors.sky500.withAlpha(51))),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: SafeArea(
        child: PremiumButton(
          text: 'Pay R${cart.total.toStringAsFixed(0)}',
          icon: Icons.lock_rounded,
          isLoading: _isProcessing,
          onPressed: () => _processPayment(cart),
        ),
      ),
    );
  }

  Future<void> _processPayment(CartState cart) async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    final bookingId = 'GRS-CART-${DateTime.now().millisecondsSinceEpoch}';
    final itemNames = cart.items.map((i) => '${i.artistName}: ${i.serviceName}').join(', ');

    try {
      final success = await PayFastService.launchPayment(
        bookingId: bookingId,
        amount: cart.total,
        artistName: 'Multiple Artists',
        serviceName: '${cart.itemCount} booking${cart.itemCount > 1 ? 's' : ''}: $itemNames',
        customerEmail: userRoleService.userEmail,
        customerFirstName: userRoleService.userName.split(' ').first,
        customerLastName: userRoleService.userName.split(' ').length > 1 ? userRoleService.userName.split(' ').last : '',
      );

      if (success) {
        ref.read(cartActionsProvider).clearCart();
        if (mounted) context.go('/cart/success');
      } else {
        if (mounted) GearshToast.error(context, 'Could not open payment page. Please try again.');
      }
    } catch (e) {
      if (mounted) GearshToast.error(context, 'Payment error. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

