import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/widgets/gearsh_background.dart';
import 'package:gearsh_app/widgets/premium_components.dart';

class CartSuccessPage extends StatefulWidget {
  const CartSuccessPage({super.key});

  @override
  State<CartSuccessPage> createState() => _CartSuccessPageState();
}

class _CartSuccessPageState extends State<CartSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Haptic feedback on success
    HapticFeedback.heavyImpact();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      ),
    );

    // Start content animation after check animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GearshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated success check
                const AnimatedSuccessCheck(size: 120),

                const SizedBox(height: 40),

                // Animated content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE2E8F0)],
                          ).createShader(bounds),
                          child: const Text(
                            'Payment Successful!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'Your booking requests have been sent to the artists. You\'ll receive a confirmation once they accept.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Info cards with staggered animation
                ...List.generate(3, (index) {
                  final items = [
                    {
                      'icon': Icons.notifications_active_rounded,
                      'title': 'Stay Notified',
                      'description': 'You\'ll receive notifications when artists respond.',
                    },
                    {
                      'icon': Icons.chat_bubble_rounded,
                      'title': 'Direct Chat',
                      'description': 'Chat with artists about event details.',
                    },
                    {
                      'icon': Icons.calendar_month_rounded,
                      'title': 'Track Bookings',
                      'description': 'Manage all bookings in the Bookings tab.',
                    },
                  ];

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600 + (index * 150)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(30 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInfoCard(
                        icon: items[index]['icon'] as IconData,
                        title: items[index]['title'] as String,
                        description: items[index]['description'] as String,
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Buttons
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      PremiumButton(
                        text: 'View My Bookings',
                        icon: Icons.calendar_today_rounded,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go('/my-bookings');
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.go('/');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: GearshColors.slate700,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Continue Exploring',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GearshColors.sky500.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: GearshColors.sky400, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

