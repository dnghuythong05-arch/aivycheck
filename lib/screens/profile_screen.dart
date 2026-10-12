import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/employee_profile_card.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onBackHome;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onBackHome,
    required this.onLogout,
  });

  Future<void> confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Đăng xuất?'),
        content: const Text('Ca làm và lịch sử chấm công vẫn được giữ lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;
    onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Cá nhân',
        subtitle: 'Thông tin và tài khoản',
        onBack: onBackHome,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AiVieTheme.contentWidth,
              ),
              child: SizedBox(
                width: double.infinity,
                child: EmployeeProfileCard(
                  fullName: user.fullName,
                  email: user.email,
                  roleName: user.roleLabel,
                  onLogout: () => confirmLogout(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
