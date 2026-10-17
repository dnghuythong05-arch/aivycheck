import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'login_screens.dart';

class MainScreens extends StatelessWidget {
  const MainScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AiVie.check',
          theme: AiVieTheme.light,
          darkTheme: AiVieTheme.dark,
          themeMode: mode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
