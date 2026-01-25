// Gearsh App - Block & Report UI Widgets
// Reusable UI components for blocking and reporting users
// Required for Apple App Store compliance

import 'package:flutter/material.dart';
import 'package:gearsh_app/services/block_report_service.dart';

// Color constants
const Color _slate950 = Color(0xFF020617);
const Color _slate900 = Color(0xFF0F172A);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate400 = Color(0xFF94A3B8);
const Color _sky500 = Color(0xFF0EA5E9);
const Color _red500 = Color(0xFFEF4444);
const Color _red400 = Color(0xFFF87171);
const Color _amber500 = Color(0xFFF59E0B);

/// Show the block/report options menu
void showBlockReportMenu(
  BuildContext context, {
  required String userId,
  required String userName,
  VoidCallback? onBlocked,
  VoidCallback? onReported,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _BlockReportSheet(
      userId: userId,
      userName: userName,
      onBlocked: onBlocked,
      onReported: onReported,
    ),
  );
}

class _BlockReportSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final VoidCallback? onBlocked;
  final VoidCallback? onReported;

  const _BlockReportSheet({
    required this.userId,
    required this.userName,
    this.onBlocked,
    this.onReported,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = blockReportService.isBlocked(userId);

    return Container(
      decoration: const BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Block option
          _buildOption(
            context,
            icon: isBlocked ? Icons.check_circle : Icons.block,
            iconColor: isBlocked ? _sky500 : _amber500,
            title: isBlocked ? 'Unblock User' : 'Block User',
            subtitle: isBlocked
                ? 'Allow this user to contact you again'
                : 'They won\'t be able to contact you',
            onTap: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              if (isBlocked) {
                await blockReportService.unblockUser(userId);
                _showSnackBarWithMessenger(scaffoldMessenger, 'User unblocked');
              } else {
                await blockReportService.blockUser(userId);
                _showSnackBarWithMessenger(scaffoldMessenger, 'User blocked');
                onBlocked?.call();
              }
            },
          ),

          // Report option
          _buildOption(
            context,
            icon: Icons.flag_outlined,
            iconColor: _red400,
            title: 'Report User',
            subtitle: 'Report inappropriate behavior',
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(context, userId, userName, onReported);
            },
          ),

          // Cancel
          Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _slate800,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _slate400.withAlpha(51)),
                ),
                child: const Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _slate800.withAlpha(128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _sky500.withAlpha(26)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _slate400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _slate400, size: 24),
          ],
        ),
      ),
    );
  }


  void _showSnackBarWithMessenger(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _slate800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Show report dialog
void _showReportDialog(
  BuildContext context,
  String userId,
  String userName,
  VoidCallback? onReported,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ReportUserSheet(
      userId: userId,
      userName: userName,
      onReported: onReported,
    ),
  );
}

class _ReportUserSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback? onReported;

  const _ReportUserSheet({
    required this.userId,
    required this.userName,
    this.onReported,
  });

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  ReportReason? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _red500.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flag_outlined, color: _red400, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.userName,
                          style: TextStyle(color: _slate400, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reason label
              const Text(
                'Why are you reporting this user?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Reason options
              ...ReportReason.values.map((reason) => _buildReasonOption(reason)),

              const SizedBox(height: 20),

              // Additional details
              const Text(
                'Additional details (optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Provide more context about the issue...',
                  hintStyle: TextStyle(color: _slate400),
                  filled: true,
                  fillColor: _slate950,
                  counterStyle: TextStyle(color: _slate400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _slate400.withAlpha(77)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _slate400.withAlpha(77)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _sky500),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              GestureDetector(
                onTap: _selectedReason != null && !_isSubmitting
                    ? _submitReport
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedReason != null ? _red500 : _slate800,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Report',
                            style: TextStyle(
                              color: _selectedReason != null
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              // Cancel button
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonOption(ReportReason reason) {
    final isSelected = _selectedReason == reason;
    String text;
    switch (reason) {
      case ReportReason.spam:
        text = 'Spam or misleading';
        break;
      case ReportReason.harassment:
        text = 'Harassment or bullying';
        break;
      case ReportReason.inappropriateContent:
        text = 'Inappropriate content';
        break;
      case ReportReason.fraud:
        text = 'Fraud or scam';
        break;
      case ReportReason.impersonation:
        text = 'Impersonation';
        break;
      case ReportReason.other:
        text = 'Other';
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _red500.withAlpha(26) : _slate800.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _red500 : _slate400.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _red500 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _red500 : _slate400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : _slate400,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    final report = await blockReportService.reportUser(
      reportedUserId: widget.userId,
      reason: _selectedReason!,
      details: _detailsController.text.isNotEmpty ? _detailsController.text : null,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    Navigator.pop(context);

    if (report != null) {
      widget.onReported?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your report. We\'ll review it shortly.'),
          backgroundColor: _slate800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

/// Icon button for triggering block/report menu
class BlockReportButton extends StatelessWidget {
  final String userId;
  final String userName;
  final VoidCallback? onBlocked;
  final VoidCallback? onReported;
  final Color? iconColor;
  final double? iconSize;

  const BlockReportButton({
    super.key,
    required this.userId,
    required this.userName,
    this.onBlocked,
    this.onReported,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showBlockReportMenu(
        context,
        userId: userId,
        userName: userName,
        onBlocked: onBlocked,
        onReported: onReported,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _slate900.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 24,
        ),
      ),
    );
  }
}
