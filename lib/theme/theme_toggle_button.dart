import 'package:flutter/material.dart';

import 'theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: controller.saving,
          builder: (context, saving, _) {
            return IconButton(
              tooltip: mode == ThemeMode.dark
                  ? 'Chuyển sang giao diện sáng'
                  : 'Chuyển sang giao diện tối',
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      try {
                        await controller.toggle();
                      } catch (_) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chưa lưu được giao diện. Hãy thử lại.',
                            ),
                          ),
                        );
                      }
                    },
            );
          },
        );
      },
    );
  }
}
