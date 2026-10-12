import 'package:aivycheck/total/login_screens.dart';
import 'package:aivycheck/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainScreens extends StatelessWidget {
  const MainScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AiVie.check',
      theme: AiVieTheme.light,
      home: LoginScreen(),
    );
  }
}
