import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aivycheck/models/attendance_session.dart';
import 'package:aivycheck/total/employee_main_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const rememberedLoginKey = 'aivycheck_remembered_login_v1';

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final session = AttendanceSession();
  final preferences = SharedPreferencesAsync();

  bool obscurePassword = true;
  bool rememberLogin = false;
  bool rememberedLoginLoaded = false;
  bool loading = true;
  bool opening = false;
  bool updatingRemember = false;

  String? error;
  String? rememberNotice;

  bool get blocked => loading || opening || updatingRemember;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> restoreRememberedLogin() async {
    final text = await preferences.getString(rememberedLoginKey);

    if (text == null) return;

    final json = Map<String, dynamic>.from(jsonDecode(text) as Map);
    final username = json['username'];
    final password = json['password'];

    if (json['version'] != 1 ||
        username is! String ||
        username.trim().isEmpty ||
        password is! String ||
        password.isEmpty) {
      await preferences.remove(rememberedLoginKey);
      return;
    }

    if (!mounted) return;

    usernameController.text = username;
    passwordController.text = password;
    rememberLogin = true;
  }

  Future<void> loadAccounts() async {
    if (opening || updatingRemember) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await session.load();

      if (!mounted) return;

      if (!rememberedLoginLoaded) {
        try {
          await restoreRememberedLogin();
        } catch (_) {
          if (!mounted) return;
          rememberNotice =
              'Chưa đọc được thông tin đã nhớ. '
              'Bạn vẫn có thể nhập tài khoản và mật khẩu để đăng nhập.';
        }

        rememberedLoginLoaded = true;
      }

      if (!mounted) return;

      setState(() => loading = false);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Chưa đọc được dữ liệu tài khoản. Hãy thử lại.';
      });
    }
  }

  Future<void> changeRememberLogin(bool? value) async {
    if (blocked || value == null) return;

    if (value) {
      setState(() {
        rememberLogin = true;
        rememberNotice = null;
      });
      return;
    }

    setState(() {
      rememberLogin = false;
      updatingRemember = true;
      rememberNotice = null;
    });

    try {
      await preferences.remove(rememberedLoginKey);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        rememberLogin = true;
        rememberNotice = 'Chưa xóa được thông tin đã nhớ. Hãy thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => updatingRemember = false);
      }
    }
  }

  Future<void> login() async {
    if (blocked) return;
    if (!formKey.currentState!.validate()) return;

    final username = usernameController.text.trim().toLowerCase();
    final password = passwordController.text;
    final message = session.signIn(username, password);

    if (message != null) {
      setState(() => error = message);
      return;
    }

    setState(() {
      opening = true;
      error = null;
      rememberNotice = null;
    });

    try {
      if (rememberLogin) {
        await preferences.setString(
          rememberedLoginKey,
          jsonEncode({
            'version': 1,
            'username': username,
            'password': password,
          }),
        );
      } else {
        await preferences.remove(rememberedLoginKey);
      }
    } catch (_) {
      session.signOut();

      if (!mounted) return;

      setState(() {
        opening = false;
        error = 'Chưa lưu được lựa chọn ghi nhớ. Hãy thử lại.';
      });
      return;
    }

    if (!mounted) {
      session.signOut();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EmployeeMainScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Image.asset('assets/images/logo.png', width: 230),
                    const SizedBox(height: 20),
                    const Text(
                      'Quản lý nhân sự & chấm công',
                      style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: usernameController,
                      enabled: !blocked,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Tài khoản',
                        hintText: 'Nhập tên tài khoản',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Hãy nhập tài khoản.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: passwordController,
                      enabled: !blocked,
                      obscureText: obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      onFieldSubmitted: (_) => login(),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: blocked
                              ? null
                              : () => setState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Hãy nhập mật khẩu.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: rememberLogin,
                      onChanged: blocked ? null : changeRememberLogin,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF2582F5),
                      title: const Text(
                        'Nhớ tài khoản và mật khẩu',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    if (rememberNotice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        rememberNotice!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFB91C1C)),
                      ),
                      TextButton(
                        onPressed: blocked ? null : loadAccounts,
                        child: const Text('Tải lại dữ liệu'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: blocked ? null : login,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2582F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: blocked
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
