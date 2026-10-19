import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/attendance_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class EmployeeEditorScreen extends StatefulWidget {
  final AttendanceSession session;
  final AppUser? initialUser;

  const EmployeeEditorScreen({
    super.key,
    required this.session,
    this.initialUser,
  });

  @override
  State<EmployeeEditorScreen> createState() => _EmployeeEditorScreenState();
}

class _EmployeeEditorScreenState extends State<EmployeeEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController usernameController;
  late final TextEditingController emailController;
  final passwordController = TextEditingController();

  bool busy = false;
  bool obscurePassword = true;
  String? error;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    nameController = TextEditingController(text: user?.fullName ?? '');
    usernameController = TextEditingController(text: user?.username ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });

    final message = await widget.session.saveEmployee(
      id: widget.initialUser?.id,
      username: usernameController.text,
      fullName: nameController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;
    if (message != null) {
      setState(() {
        busy = false;
        error = message;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Hãy nhập thông tin.' : null;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final colors = AiVieTheme.of(context);
    final editing = widget.initialUser != null;

    return Scaffold(
      appBar: AppHeader(
        title: editing ? 'Chỉnh tài khoản' : 'Tạo nhân viên',
        subtitle: 'Thông tin tài khoản nhân viên',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                            ),
                            validator: requiredText,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: usernameController,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Tên tài khoản',
                            ),
                            validator: requiredText,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(value.trim())) {
                                return 'Hãy nhập email hợp lệ.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: editing ? 'Mật khẩu mới' : 'Mật khẩu',
                              helperText: editing
                                  ? 'Để trống nếu giữ mật khẩu hiện tại.'
                                  : null,
                              suffixIcon: IconButton(
                                tooltip: obscurePassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () => setState(() {
                                  obscurePassword = !obscurePassword;
                                }),
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                !editing && (value == null || value.isEmpty)
                                ? 'Hãy nhập mật khẩu.'
                                : null,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                          Text(
                            'Vai trò: Nhân viên',
                            style: AiVieTheme.secondary(context),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              error!,
                              style: typography.bodyMedium?.copyWith(
                                color: colors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: busy ? null : save,
                            icon: const Icon(Icons.save_outlined, size: 20),
                            label: Text(busy ? 'Đang lưu…' : 'Lưu tài khoản'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
