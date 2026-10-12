import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmployeeProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final VoidCallback? onLogout;
  final bool loggingOut;
  final String roleName;

  const EmployeeProfileCard({
    super.key,
    required this.fullName,
    required this.email,
    required this.onLogout,
    this.loggingOut = false,
    this.roleName = 'Nhân viên',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = fullName.trim();
    final displayEmail = email.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AiVieTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 26,
                        color: AiVieTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Họ và tên',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AiVieTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName.isEmpty
                                ? 'Chưa có họ tên'
                                : displayName,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),
                _ProfileInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Vai trò',
                  value: roleName,
                ),
                const SizedBox(height: 20),
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: displayEmail.isEmpty ? 'Chưa có email' : displayEmail,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: loggingOut ? null : onLogout,
          icon: loggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDC2626),
                  ),
                )
              : const Icon(Icons.logout_rounded, size: 20),
          label: Text(loggingOut ? 'Đang đăng xuất…' : 'Đăng xuất'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFFECACA)),
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AiVieTheme.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.bodySmall?.copyWith(color: AiVieTheme.muted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: typography.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
