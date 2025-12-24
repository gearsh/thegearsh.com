import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/widgets/auth_prompt.dart';

class BookingFlowPage extends StatefulWidget {
  final String artistId;
  final String? artistName;
  final String? serviceName;
  final double? servicePrice;

  const BookingFlowPage({
    super.key,
    required this.artistId,
    this.artistName,
    this.serviceName,
    this.servicePrice,
  });

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage>
    with SingleTickerProviderStateMixin {
  // Current step: 'details' or 'payment'
  String _currentStep = 'details';

  // Form controllers
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedCardId = 'card1';

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Pricing
  late double _servicePrice;
  static const double _serviceFeePercentage = 0.126; // 12.6% service fee

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  // Mock saved cards
  final List<Map<String, String>> _savedCards = [
    {'id': 'card1', 'brand': 'Visa', 'last4': '4242', 'expiry': '12/25'},
    {'id': 'card2', 'brand': 'Mastercard', 'last4': '8888', 'expiry': '09/26'},
  ];

  @override
  void initState() {
    super.initState();
    _servicePrice = widget.servicePrice ?? 500.0;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Check if guest user trying to book
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRoleService.requiresSignUp) {
        showSignUpPrompt(context, featureName: 'book artists');
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double get _serviceFee => _servicePrice * _serviceFeePercentage;
  double get _total => _servicePrice + _serviceFee;

  String get _artistName => widget.artistName ?? 'Artist';
  String get _serviceName => widget.serviceName ?? 'Booking Service';

  void _handleBack() {
    if (_currentStep == 'payment') {
      setState(() => _currentStep = 'details');
    } else {
      Navigator.pop(context);
    }
  }

  void _handleContinue() {
    if (_currentStep == 'details') {
      setState(() => _currentStep = 'payment');
    } else {
      // Complete booking - navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessPage(
            artistName: _artistName,
            serviceName: _serviceName,
            date: _selectedDate,
            time: _selectedTime,
            total: _total,
          ),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _sky500,
            onPrimary: Colors.white,
            surface: _slate800,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _sky500,
            onPrimary: Colors.white,
            surface: _slate800,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.only(
                    top: padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _slate950.withAlpha(242),
                    border: const Border(
                      bottom: BorderSide(
                        color: Color(0x330EA5E9),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Back button and title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _handleBack,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _slate900.withAlpha(128),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: _sky500.withAlpha(77),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentStep == 'details'
                                      ? 'Booking Details'
                                      : 'Payment',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_artistName - $_serviceName',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(153),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_sky500, _cyan500],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _sky500.withAlpha(153),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: _currentStep == 'payment'
                                    ? const LinearGradient(
                                        colors: [_sky500, _cyan500],
                                      )
                                    : null,
                                color: _currentStep == 'payment'
                                    ? null
                                    : _slate800,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: _currentStep == 'payment'
                                    ? [
                                        BoxShadow(
                                          color: _sky500.withAlpha(153),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _currentStep == 'details'
                          ? _buildDetailsStep()
                          : _buildPaymentStep(),
                    ),
                  ),
                ),

                // Bottom spacer for button
                const SizedBox(height: 100),
              ],
            ),

            // Bottom button
            Positioned(
              bottom: padding.bottom + 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: _handleContinue,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_sky500, _cyan500],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _sky500.withAlpha(102),
                        blurRadius: 25,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentStep == 'details'
                          ? 'Continue to Payment'
                          : 'Confirm Booking Request',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service selected
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'High-energy experience with full setup',
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'R${_servicePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _sky400,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Date & Time
        _buildInputField(
          icon: Icons.calendar_today_rounded,
          label: 'Event Date',
          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          onTap: _selectDate,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          icon: Icons.access_time_rounded,
          label: 'Start Time',
          value: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          onTap: _selectTime,
        ),
        const SizedBox(height: 12),

        // Location
        _buildTextInputField(
          icon: Icons.location_on_outlined,
          label: 'Event Location',
          controller: _locationController,
          placeholder: 'Enter venue address',
        ),
        const SizedBox(height: 12),

        // Notes
        _buildTextInputField(
          icon: Icons.description_outlined,
          label: 'Additional Notes',
          controller: _notesController,
          placeholder: 'Any special requests or details...',
          maxLines: 4,
        ),
        const SizedBox(height: 20),

        // Price Summary
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceRow('Service Price', 'R${_servicePrice.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildPriceRow('Service Fee (12.6%)', 'R${_serviceFee.toStringAsFixed(2)}'),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'R${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _sky400,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saved cards
        const Text(
          'Saved Payment Methods',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Card list
        ..._savedCards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentCard(card),
            )),

        // Add card button
        GestureDetector(
          onTap: () {
            // TODO: Add new card flow
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _slate900.withAlpha(102),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _sky500.withAlpha(51)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _sky500.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: _sky400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Payment Method',
                  style: TextStyle(
                    color: _sky400,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Booking summary
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Artist', _artistName),
              const SizedBox(height: 8),
              _buildSummaryRow('Service', _serviceName),
              const SizedBox(height: 8),
              _buildSummaryRow('Date', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              const SizedBox(height: 8),
              _buildSummaryRow('Time', '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
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
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'R${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _sky400,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Terms
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _slate900.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _sky500.withAlpha(25)),
          ),
          child: Text(
            'By confirming, you agree to our Terms of Service and acknowledge that payment will be processed upon artist confirmation.',
            style: TextStyle(
              color: Colors.white.withAlpha(153),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: child,
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _sky400, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _slate900.withAlpha(128),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _sky500.withAlpha(77)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _sky400, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.white.withAlpha(102)),
            filled: true,
            fillColor: _slate900.withAlpha(128),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _sky500.withAlpha(77)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _sky500.withAlpha(77)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _sky500, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, String> card) {
    final isSelected = _selectedCardId == card['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCardId = card['id']!),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _sky500.withAlpha(25) : _slate900.withAlpha(102),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _sky500 : _sky500.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _sky500.withAlpha(51),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_sky500, _cyan500],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${card['brand']} •••• ${card['last4']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Expires ${card['expiry']}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _sky500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Booking Success Page
class BookingSuccessPage extends StatelessWidget {
  final String artistName;
  final String serviceName;
  final DateTime date;
  final TimeOfDay time;
  final double total;

  const BookingSuccessPage({
    super.key,
    required this.artistName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.total,
  });

  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_sky500, _cyan500],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _sky500.withAlpha(102),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_sky400, _cyan500],
                  ).createShader(bounds),
                  child: const Text(
                    'Booking Requested!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Your booking request has been sent to $artistName. You\'ll receive a confirmation once accepted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Booking details card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _slate900.withAlpha(128),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _sky500.withAlpha(51)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Service', serviceName),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', '${date.day}/${date.month}/${date.year}'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Time', '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                      const SizedBox(height: 12),
                      Container(height: 1, color: _sky500.withAlpha(51)),
                      const SizedBox(height: 12),
                      _buildDetailRow('Total', 'R${total.toStringAsFixed(2)}', isTotal: true),
                    ],
                  ),
                ),
                const Spacer(),

                // View bookings button
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_sky500, _cyan500],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _sky500.withAlpha(102),
                          blurRadius: 25,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? _sky400 : Colors.white,
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

