import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/attendance_session.dart';
import '../services/api_client.dart';
import '../services/employee_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/employee_account_card.dart';
import 'employee_details_screen.dart';
import 'employee_editor_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final AttendanceSession session;
  final VoidCallback onBackHome;

  const EmployeesScreen({
    super.key,
    required this.session,
    required this.onBackHome,
  });

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool busy = false;
  String? error;
  final Set<String> deletedUserIds = {};

  Future<void> refreshEmployees() async {
    if (busy || !widget.session.isAdmin) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final message = await widget.session.loadEmployees();

      if (mounted) {
        setState(() => error = message);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> deleteEmployee(AppUser user) async {
    if (busy || !widget.session.isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản nhân viên?'),
        content: Text(
          '${user.fullName}\n@${user.username}\n\n'
          'Nhân viên sẽ không đăng nhập được nữa. '
          'Dữ liệu chấm công cũ vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || busy) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await EmployeeService(widget.session.auth).delete(user.id);

      if (mounted) {
        setState(() => deletedUserIds.add(user.id));
      }

      final refreshError = await widget.session.loadEmployees();

      if (!mounted) return;

      setState(() => error = refreshError);

      final colors = AiVieTheme.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshError == null
                ? 'Đã xóa tài khoản ${user.username}.'
                : 'Tài khoản đã xóa. Chưa tải lại được danh sách, '
                      'hãy thử tải lại.',
            style: TextStyle(
              color: refreshError == null ? colors.success : colors.warning,
            ),
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (failure) {
      if (mounted) {
        setState(() => error = failure.message);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> editEmployee([AppUser? user]) async {
    if (busy) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeEditorScreen(session: widget.session, initialUser: user),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openEmployee(AppUser user) async {
    if (busy) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeDetailsScreen(session: widget.session.forEmployee(user.id)),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            'Chỉ Admin được mở mục này.',
            style: AiVieTheme.secondary(context),
          ),
        ),
      );
    }

    final users = widget.session.employees
        .where((user) => !deletedUserIds.contains(user.id))
        .toList();

    return Scaffold(
      appBar: AppHeader(
        title: 'Nhân viên',
        subtitle: 'Tài khoản, ca làm và lịch sử',
        onBack: widget.onBackHome,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AiVieTheme.contentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : () => editEmployee(),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 20,
                        ),
                        label: const Text('Tạo tài khoản nhân viên'),
                      ),
                      TextButton.icon(
                        onPressed: busy ? null : refreshEmployees,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tải lại danh sách'),
                      ),
                    ],
                  ),
                ),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      error!,
                      style: TextStyle(color: AiVieTheme.of(context).error),
                    ),
                  ),
                Expanded(
                  child: users.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có nhân viên.',
                            style: AiVieTheme.secondary(context),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: users.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final user = users[index];

                            return EmployeeAccountCard(
                              user: user,
                              onOpen: busy ? null : () => openEmployee(user),
                              onEdit: busy ? null : () => editEmployee(user),
                              onDelete: busy
                                  ? null
                                  : () => deleteEmployee(user),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
