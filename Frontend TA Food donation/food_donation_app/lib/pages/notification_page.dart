import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NotificationPage extends StatefulWidget {
  final String token;

  const NotificationPage({
    super.key,
    required this.token,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late List<_AppNotification> _notifications;

  _NotificationFilter _activeFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();

    _notifications = _mockNotifications();
  }

  List<_AppNotification> _mockNotifications() {
    final DateTime now = DateTime.now();

    return [
      _AppNotification(
        id: 'n1',
        title: 'Donasi makanan tersedia',
        message:
            'Ada paket makanan baru dalam radius terdekat. Periksa lokasi pickup sebelum klaim.',
        category: _NotificationCategory.food,
        createdAt: now.subtract(const Duration(minutes: 8)),
        isUnread: true,
        actionLabel: 'Lihat Maps',
      ),
      _AppNotification(
        id: 'n2',
        title: 'Status pengambilan diperbarui',
        message:
            'Klaim makanan Anda sedang dalam proses. Gunakan fitur chat bila butuh koordinasi.',
        category: _NotificationCategory.food,
        createdAt: now.subtract(const Duration(minutes: 27)),
        isUnread: true,
        actionLabel: 'Lihat Riwayat',
      ),
      _AppNotification(
        id: 'n3',
        title: 'Pesan baru',
        message:
            'Donatur mengirim pesan terkait lokasi pengambilan makanan.',
        category: _NotificationCategory.chat,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        isUnread: true,
        actionLabel: 'Buka Chat',
      ),
      _AppNotification(
        id: 'n4',
        title: 'Simulasi bandwidth upload',
        message:
            'Foto donasi berhasil dianalisis. Estimasi payload gambar tersimpan untuk bahan analisis jaringan.',
        category: _NotificationCategory.network,
        createdAt: now.subtract(const Duration(hours: 3)),
        isUnread: false,
        actionLabel: 'Detail',
      ),
      _AppNotification(
        id: 'n5',
        title: 'Keamanan akun',
        message:
            'Akun User aktif. Satu akun dapat digunakan sebagai donatur dan konsumen.',
        category: _NotificationCategory.system,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isUnread: false,
        actionLabel: 'Profil',
      ),
      _AppNotification(
        id: 'n6',
        title: 'Mockup VoIP aktif',
        message:
            'Frontend Audio Call dan Video Call sudah tersedia sebagai simulasi komunikasi in-app.',
        category: _NotificationCategory.network,
        createdAt: now.subtract(const Duration(days: 2)),
        isUnread: false,
        actionLabel: 'Cek Fitur',
      ),
    ];
  }

  List<_AppNotification> get _filteredNotifications {
    switch (_activeFilter) {
      case _NotificationFilter.unread:
        return _notifications.where((item) => item.isUnread).toList();
      case _NotificationFilter.food:
        return _notifications
            .where((item) => item.category == _NotificationCategory.food)
            .toList();
      case _NotificationFilter.chat:
        return _notifications
            .where((item) => item.category == _NotificationCategory.chat)
            .toList();
      case _NotificationFilter.network:
        return _notifications
            .where((item) => item.category == _NotificationCategory.network)
            .toList();
      case _NotificationFilter.system:
        return _notifications
            .where((item) => item.category == _NotificationCategory.system)
            .toList();
      case _NotificationFilter.all:
        return _notifications;
    }
  }

  int get _unreadCount {
    return _notifications.where((item) => item.isUnread).length;
  }

  void _changeFilter(_NotificationFilter filter) {
    setState(() {
      _activeFilter = filter;
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map(
            (item) => item.copyWith(isUnread: false),
          )
          .toList();
    });

    _showSnack(
      'Semua notifikasi ditandai sudah dibaca.',
      isError: false,
    );
  }

  void _toggleReadStatus(String id) {
    setState(() {
      _notifications = _notifications.map((item) {
        if (item.id != id) return item;
        return item.copyWith(isUnread: !item.isUnread);
      }).toList();
    });
  }

  void _handleNotificationTap(_AppNotification notification) {
    if (notification.isUnread) {
      _toggleReadStatus(notification.id);
    }

    _showSnack(
      '${notification.title}: fitur navigasi spesifik akan dihubungkan pada tahap integrasi backend.',
      isError: false,
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }

    return '${difference.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final List<_AppNotification> visibleNotifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            96,
          ),
          children: [
            _NotificationHeader(
              unreadCount: _unreadCount,
              onMarkAllRead: _unreadCount == 0 ? null : _markAllAsRead,
            ),
            const SizedBox(height: AppSpacing.x3),
            _FilterBar(
              activeFilter: _activeFilter,
              unreadCount: _unreadCount,
              onChanged: _changeFilter,
            ),
            const SizedBox(height: AppSpacing.x3),
            if (visibleNotifications.isEmpty)
              const _EmptyNotificationState()
            else
              ...visibleNotifications.map(
                (notification) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                    child: _NotificationCard(
                      notification: notification,
                      timeLabel: _relativeTime(notification.createdAt),
                      onTap: () => _handleNotificationTap(notification),
                      onToggleRead: () => _toggleReadStatus(notification.id),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onMarkAllRead;

  const _NotificationHeader({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.primaryDark,
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifikasi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unreadCount == 0
                        ? 'Tidak ada notifikasi baru.'
                        : '$unreadCount notifikasi belum dibaca.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text('Tandai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _NotificationFilter activeFilter;
  final int unreadCount;
  final ValueChanged<_NotificationFilter> onChanged;

  const _FilterBar({
    required this.activeFilter,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<_FilterItem> filters = [
      const _FilterItem(
        filter: _NotificationFilter.all,
        label: 'Semua',
      ),
      _FilterItem(
        filter: _NotificationFilter.unread,
        label: 'Unread $unreadCount',
      ),
      const _FilterItem(
        filter: _NotificationFilter.food,
        label: 'Makanan',
      ),
      const _FilterItem(
        filter: _NotificationFilter.chat,
        label: 'Chat',
      ),
      const _FilterItem(
        filter: _NotificationFilter.network,
        label: 'Network',
      ),
      const _FilterItem(
        filter: _NotificationFilter.system,
        label: 'Sistem',
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.x1);
        },
        itemBuilder: (context, index) {
          final _FilterItem item = filters[index];
          final bool isActive = activeFilter == item.filter;

          return ChoiceChip(
            selected: isActive,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
            label: Text(item.label),
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isActive ? Colors.white : AppColors.primaryDark,
                ),
            onSelected: (selected) => onChanged(item.filter),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _AppNotification notification;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;

  const _NotificationCard({
    required this.notification,
    required this.timeLabel,
    required this.onTap,
    required this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = _categoryColor(notification.category);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: notification.isUnread
              ? categoryColor.withValues(alpha: 0.26)
              : AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(
                        _categoryIcon(notification.category),
                        color: categoryColor,
                      ),
                    ),
                    if (notification.isUnread)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: notification.isUnread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          Text(
                            timeLabel,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Row(
                        children: [
                          _CategoryPill(
                            label: _categoryLabel(notification.category),
                            color: categoryColor,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: onToggleRead,
                            child: Text(
                              notification.isUnread
                                  ? 'Sudah dibaca'
                                  : 'Belum dibaca',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(_NotificationCategory category) {
    switch (category) {
      case _NotificationCategory.food:
        return Icons.fastfood_rounded;
      case _NotificationCategory.chat:
        return Icons.chat_bubble_outline_rounded;
      case _NotificationCategory.network:
        return Icons.network_check_rounded;
      case _NotificationCategory.system:
        return Icons.security_rounded;
    }
  }

  String _categoryLabel(_NotificationCategory category) {
    switch (category) {
      case _NotificationCategory.food:
        return 'Makanan';
      case _NotificationCategory.chat:
        return 'Chat';
      case _NotificationCategory.network:
        return 'Network';
      case _NotificationCategory.system:
        return 'Sistem';
    }
  }

  Color _categoryColor(_NotificationCategory category) {
    switch (category) {
      case _NotificationCategory.food:
        return AppColors.primary;
      case _NotificationCategory.chat:
        return AppColors.teal;
      case _NotificationCategory.network:
        return AppColors.accent;
      case _NotificationCategory.system:
        return AppColors.primaryDark;
    }
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.textSecondary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'Tidak Ada Notifikasi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              'Notifikasi pada kategori ini belum tersedia.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppNotification {
  final String id;
  final String title;
  final String message;
  final _NotificationCategory category;
  final DateTime createdAt;
  final bool isUnread;
  final String actionLabel;

  const _AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isUnread,
    required this.actionLabel,
  });

  _AppNotification copyWith({
    bool? isUnread,
  }) {
    return _AppNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      createdAt: createdAt,
      isUnread: isUnread ?? this.isUnread,
      actionLabel: actionLabel,
    );
  }
}

class _FilterItem {
  final _NotificationFilter filter;
  final String label;

  const _FilterItem({
    required this.filter,
    required this.label,
  });
}

enum _NotificationCategory {
  food,
  chat,
  network,
  system,
}

enum _NotificationFilter {
  all,
  unread,
  food,
  chat,
  network,
  system,
}