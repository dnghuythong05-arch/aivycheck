import 'package:flutter/material.dart';
import 'package:aivycheck/total/main_screens.dart';

import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.instance.load();

  runApp(const MainScreens());
}
