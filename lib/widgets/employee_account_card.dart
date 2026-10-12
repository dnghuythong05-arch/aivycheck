import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';

class EmployeeAccountCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const EmployeeAccountCard({
    super.key,
    required this.user,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: AiVieTheme.primary.withValues(alpha: 0.02),
        focusColor: AiVieTheme.primary.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AiVieTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: AiVieTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: typography.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: typography.bodyMedium?.copyWith(
                        color: AiVieTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Giao ca · Xem lịch sử',
                      style: typography.bodySmall?.copyWith(
                        color: AiVieTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Chỉnh tài khoản',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AiVieTheme.muted,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AiVieTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
