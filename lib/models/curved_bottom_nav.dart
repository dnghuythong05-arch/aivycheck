import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

class CurvedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isAdmin;
  final bool showSalary;

  const CurvedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isAdmin = false,
    this.showSalary = false,
  }) : assert(!isAdmin || !showSalary),
       assert(
         selectedIndex >= 0 &&
             selectedIndex < ((isAdmin || showSalary) ? 5 : 4),
       );

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);

    final items = <_NavItem>[
      const _NavItem('Trang chủ', LucideIcons.house),
      const _NavItem('Chấm công', LucideIcons.calendar),
      const _NavItem('Lịch sử', LucideIcons.fileText),
      if (isAdmin) const _NavItem('Nhân viên', LucideIcons.usersRound),
      if (!isAdmin && showSalary)
        const _NavItem('Bảng lương', Icons.account_balance_wallet_outlined),
      const _NavItem('Cá nhân', LucideIcons.userRound),
    ];

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _NavButton(
                      item: items[index],
                      selected: index == selectedIndex,
                      onTap: () => onDestinationSelected(index),
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

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final color = selected ? colors.primary : colors.muted;

    final duration = Duration(
      milliseconds: MediaQuery.of(context).disableAnimations ? 0 : 180,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: colors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                width: 48,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? colors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 26, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
