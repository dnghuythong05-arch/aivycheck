import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  static final ValueNotifier<bool> _adminVisible = ValueNotifier<bool>(false);

  static void setAdminVisible(bool visible) {
    if (_adminVisible.value == visible) return;

    _adminVisible.value = visible;
  }

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(69);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _adminVisible,
      builder: (context, showAdmin, child) {
        return AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(),
          leadingWidth: onBack == null ? null : 56,
          leading: onBack == null
              ? null
              : IconButton(
                  tooltip: 'Quay lại',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: const Color(0xFF2563EB),
                ),
          titleSpacing: onBack == null ? 24 : 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          actions: showAdmin
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              : null,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: SizedBox(
              height: 1,
              width: double.infinity,
              child: ColoredBox(color: Color(0xFFE5E7EB)),
            ),
          ),
        );
      },
    );
  }
}
