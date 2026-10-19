import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/attendance_session.dart';
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
  Future<void> editEmployee([AppUser? user]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeEditorScreen(session: widget.session, initialUser: user),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> openEmployee(AppUser user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeDetailsScreen(session: widget.session.forEmployee(user.id)),
      ),
    );
    if (mounted) setState(() {});
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

    final users = widget.session.employees;

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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => editEmployee(),
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 20,
                      ),
                      label: const Text('Tạo tài khoản nhân viên'),
                    ),
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
                              onOpen: () => openEmployee(user),
                              onEdit: () => editEmployee(user),
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
