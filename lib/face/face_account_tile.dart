import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

class FaceAccountTile extends StatelessWidget {
  final AppUser user;
  final bool registered;
  final VoidCallback? onRegister;

  const FaceAccountTile({
    super.key,
    required this.user,
    required this.registered,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AiVieTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${user.username} · ${user.roleLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: AiVieTheme.muted),
            ),
            const SizedBox(height: 12),
            Text(
              registered ? 'Đã có mẫu khuôn mặt' : 'Chưa có mẫu khuôn mặt',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(registered ? 'Đổi ảnh đăng ký' : 'Chọn ảnh đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
