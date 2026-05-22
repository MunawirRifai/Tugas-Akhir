import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const List<_BottomNavItemData> _items = [
    _BottomNavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _BottomNavItemData(
      label: 'Riwayat',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_toggle_off_rounded,
    ),
    _BottomNavItemData(
      label: 'Notifikasi',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
    _BottomNavItemData(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      notchMargin: 10,
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: const CircularNotchedRectangle(),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  data: _items[0],
                  index: 0,
                  isActive: currentIndex == 0,
                  onTap: onChanged,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  data: _items[1],
                  index: 1,
                  isActive: currentIndex == 1,
                  onTap: onChanged,
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                child: _BottomNavItem(
                  data: _items[2],
                  index: 2,
                  isActive: currentIndex == 2,
                  onTap: onChanged,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  data: _items[3],
                  index: 3,
                  isActive: currentIndex == 3,
                  onTap: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _BottomNavItemData data;
  final int index;
  final bool isActive;
  final ValueChanged<int> onTap;

  const _BottomNavItem({
    required this.data,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor =
        isActive ? AppColors.primaryDark : AppColors.textMuted;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? data.activeIcon : data.icon,
                color: foregroundColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _BottomNavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}