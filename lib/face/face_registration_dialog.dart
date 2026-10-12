import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/attendance_session.dart';
import '../theme/app_theme.dart';
import 'face_account_tile.dart';

class FaceRegistrationDialog extends StatefulWidget {
  final AttendanceSession session;

  const FaceRegistrationDialog({super.key, required this.session});

  @override
  State<FaceRegistrationDialog> createState() => _FaceRegistrationDialogState();
}

class _FaceRegistrationDialogState extends State<FaceRegistrationDialog> {
  Set<String> registeredIds = {};

  bool loading = true;
  bool busy = false;

  String? message;

  @override
  void initState() {
    super.initState();
    loadFaces();
  }

  Future<void> loadFaces() async {
    try {
      final ids = await widget.session.registeredIds();

      if (!mounted) return;

      setState(() {
        registeredIds = ids;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'Chưa đọc được dữ liệu khuôn mặt. Hãy đóng và mở lại.';
      });
    }
  }

  Future<void> register(AppUser user) async {
    if (busy || loading) return;

    setState(() {
      busy = true;
      message = null;
    });

    var saved = false;

    try {
      final error = await widget.session.registerFace(user.id);

      if (!mounted) return;

      if (error != null) {
        setState(() => message = error);
        return;
      }

      saved = true;
      final ids = await widget.session.registeredIds();

      if (!mounted) return;

      setState(() {
        registeredIds = ids;
        message = ids.contains(user.id)
            ? 'Đã lưu khuôn mặt cho ${user.fullName}.'
            : 'Đã lưu danh sách ảnh trống cho ${user.fullName}. '
                  'Tài khoản chưa có mẫu khuôn mặt.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        message = saved
            ? 'Đã lưu thay đổi nhưng chưa cập nhật được trạng thái. '
                  'Hãy đóng và mở lại.'
            : 'Chưa xử lý được khuôn mặt. Hãy thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget accountTile(AppUser user) {
    final tile = FaceAccountTile(
      user: user,
      registered: registeredIds.contains(user.id),
      onRegister: busy ? null : () => register(user),
    );

    if (!user.isAdmin) return tile;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          tile,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.session.currentUser;

    final users = [if (admin != null) admin, ...widget.session.employees];

    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        backgroundColor: AiVieTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AiVieTheme.border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Text('Đăng ký khuôn mặt', style: textTheme.titleLarge),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chọn tài khoản để xem hoặc chỉnh danh sách ảnh đăng ký. ',
                style: textTheme.bodyMedium?.copyWith(color: AiVieTheme.muted),
              ),
              const SizedBox(height: 20),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else
                for (final user in users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: accountTile(user),
                  ),
              if (busy) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(minHeight: 3),
              ],
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message!, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
