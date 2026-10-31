import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

class EmployeeAccountCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EmployeeAccountCard({
    super.key,
    required this.user,
    required this.onOpen,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: colors.primary.withValues(alpha: 0.02),
        focusColor: colors.primary.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: typography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: AiVieTheme.secondary(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Giao ca · Xem lịch sử',
                      style: AiVieTheme.secondary(context, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Chỉnh tài khoản',
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 20, color: colors.muted),
              ),
              IconButton(
                tooltip: 'Xóa tài khoản',
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  foregroundColor: colors.error,
                  disabledForegroundColor: colors.muted.withValues(alpha: 0.45),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
