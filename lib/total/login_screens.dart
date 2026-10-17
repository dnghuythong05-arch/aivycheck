import 'dart:convert';

import 'package:aivycheck/theme/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_session.dart';
import '../theme/app_theme.dart';
import 'employee_main_screens.dart';

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
  final usernameFocusNode = FocusNode();

  final Map<String, String> rememberedLogins = {};

  final session = AttendanceSession();
  final preferences = SharedPreferencesAsync();

  String? selectedRememberedUsername;

  bool obscurePassword = true;
  bool rememberLogin = false;
  bool rememberedLoginLoaded = false;

  bool loading = true;
  bool opening = false;
  bool updatingRemember = false;

  String? error;
  String? rememberNotice;

  bool get blocked {
    return loading || opening || updatingRemember;
  }

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  @override
  void dispose() {
    usernameFocusNode.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> restoreRememberedLogin() async {
    final text = await preferences.getString(rememberedLoginKey);

    if (text == null) return;

    final json = Map<String, dynamic>.from(jsonDecode(text) as Map);

    final accounts = <String, String>{};

    if (json['version'] == 1) {
      final username = json['username'];
      final password = json['password'];

      if (username is! String ||
          username.trim().isEmpty ||
          password is! String ||
          password.isEmpty) {
        throw const FormatException('Thông tin ghi nhớ không hợp lệ.');
      }

      accounts[username.trim().toLowerCase()] = password;
    } else if (json['version'] == 2 && json['accounts'] is Map) {
      for (final entry in (json['accounts'] as Map).entries) {
        final username = entry.key;
        final password = entry.value;

        if (username is String &&
            username.trim().isNotEmpty &&
            password is String &&
            password.isNotEmpty) {
          accounts[username.trim().toLowerCase()] = password;
        }
      }
    } else {
      throw const FormatException('Thông tin ghi nhớ không hợp lệ.');
    }

    if (!mounted) return;

    rememberedLogins
      ..clear()
      ..addAll(accounts);
  }

  Future<void> saveRememberedLogins(Map<String, String> accounts) async {
    if (accounts.isEmpty) {
      await preferences.remove(rememberedLoginKey);
      return;
    }

    await preferences.setString(
      rememberedLoginKey,
      jsonEncode({'version': 2, 'accounts': accounts}),
    );
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

      setState(() {
        loading = false;
      });
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

    final username = usernameController.text.trim().toLowerCase();

    final next = {...rememberedLogins}..remove(username);

    setState(() {
      rememberLogin = false;
      updatingRemember = true;
      rememberNotice = null;
    });

    try {
      await saveRememberedLogins(next);

      if (!mounted) return;

      rememberedLogins
        ..clear()
        ..addAll(next);

      selectedRememberedUsername = null;
    } catch (_) {
      if (!mounted) return;

      setState(() {
        rememberLogin = true;
        rememberNotice = 'Chưa xóa được thông tin đã nhớ. Hãy thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          updatingRemember = false;
        });
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
      setState(() {
        error = message;
      });

      return;
    }

    setState(() {
      opening = true;
      error = null;
      rememberNotice = null;
    });

    try {
      final next = {...rememberedLogins};

      if (rememberLogin) {
        next[username] = password;
      } else {
        next.remove(username);
      }

      await saveRememberedLogins(next);

      rememberedLogins
        ..clear()
        ..addAll(next);
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

  Widget buildUsernameField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = AiVieTheme.of(context);

        return RawAutocomplete<String>(
          textEditingController: usernameController,
          focusNode: usernameFocusNode,
          optionsBuilder: (value) {
            if (blocked || value.text.trim().isEmpty) {
              return const Iterable<String>.empty();
            }

            final query = value.text.trim().toLowerCase();

            return rememberedLogins.keys
                .where((username) => username.startsWith(query))
                .toList()
              ..sort();
          },
          onSelected: (username) {
            if (blocked) return;

            setState(() {
              selectedRememberedUsername = username;
              passwordController.text = rememberedLogins[username]!;

              rememberLogin = true;
              error = null;
              rememberNotice = null;
            });

            FocusScope.of(context).unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: !blocked,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: null,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => onSubmitted(),
              onChanged: (value) {
                if (selectedRememberedUsername != null &&
                    value.trim().toLowerCase() != selectedRememberedUsername) {
                  selectedRememberedUsername = null;
                }
              },
              style: TextStyle(color: colors.text),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                labelText: 'Tài khoản',
                hintText: 'Nhập tên tài khoản',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: colors.surface,
                labelStyle: TextStyle(color: colors.muted),
                hintStyle: TextStyle(color: colors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Hãy nhập tài khoản.';
                }

                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final colors = AiVieTheme.of(context);
            final accounts = options.toList();

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final username = accounts[index];

                        return ListTile(
                          leading: Icon(
                            Icons.person_outline,
                            color: colors.muted,
                          ),
                          title: Text(
                            username,
                            style: TextStyle(color: colors.text),
                          ),
                          onTap: blocked ? null : () => onSelected(username),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ThemeToggleButton(), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AiVieTheme.of(context).background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset('assets/images/logo.png', width: 230),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Quản lý nhân sự & chấm công',
                      style: TextStyle(fontSize: 16, color: colors.muted),
                    ),
                    const SizedBox(height: 32),
                    buildUsernameField(),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: passwordController,
                      enabled: !blocked,
                      obscureText: obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: TextStyle(color: colors.text),
                      cursorColor: colors.primary,
                      onFieldSubmitted: (_) => login(),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: TextStyle(color: colors.muted),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: blocked
                              ? null
                              : () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Hãy nhập mật khẩu.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: rememberLogin,
                      onChanged: blocked ? null : changeRememberLogin,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF2582F5),
                      checkColor: Colors.white,
                      title: Text(
                        'Nhớ tài khoản và mật khẩu',
                        style: TextStyle(fontSize: 14, color: colors.text),
                      ),
                    ),
                    if (rememberNotice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        rememberNotice!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.muted),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.error),
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
                          foregroundColor: Colors.white,
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
                                  color: Colors.white,
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
