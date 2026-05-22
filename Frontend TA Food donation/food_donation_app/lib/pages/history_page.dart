import 'package:flutter/material.dart';

import '../services/food_service.dart';
import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';
import 'edit_food_page.dart';
import 'food_detail_page.dart';

class HistoryPage extends StatefulWidget {
  final String token;

  const HistoryPage({
    super.key,
    required this.token,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isRefreshing = false;

  List<FoodRecord> _donations = [];
  List<FoodRecord> _claims = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final Map<String, dynamic> history =
          await FoodService.getHistory(widget.token);

      if (!mounted) return;

      setState(() {
        _donations = FoodMapper.recordsFromHistory(
          history,
          [
            'myDonation',
            'myDonations',
            'donations',
            'donationHistory',
            'postedFoods',
          ],
        );

        _claims = FoodMapper.recordsFromHistory(
          history,
          [
            'myClaim',
            'myClaims',
            'claims',
            'claimHistory',
            'claimedFoods',
          ],
        );
      });
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memuat riwayat: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _openDetail(
    FoodRecord food,
    FoodDetailMode mode,
  ) async {
    final bool? shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodDetailPage(
          token: widget.token,
          food: food.toMap(),
          mode: mode,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _loadHistory(isRefresh: true);
    }
  }

  Future<void> _openEdit(FoodRecord food) async {
    final bool? shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditFoodPage(
          token: widget.token,
          food: food.toMap(),
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _loadHistory(isRefresh: true);
    }
  }

  Future<void> _deleteFood(FoodRecord food) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: const Text('Hapus Postingan?'),
          content: Text(
            'Postingan "${food.name}" akan dihapus permanen dari daftar donasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final int? foodId = food.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    try {
      await FoodService.deleteFood(
        token: widget.token,
        foodId: foodId,
      );

      if (!mounted) return;

      _showSnack(
        'Postingan berhasil dihapus.',
        isError: false,
      );

      await _loadHistory(isRefresh: true);
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menghapus postingan: $error',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _HistorySkeletonPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x3,
                    AppSpacing.x2,
                    AppSpacing.x3,
                    AppSpacing.x1,
                  ),
                  child: _HistoryHeader(
                    donationCount: _donations.length,
                    claimCount: _claims.length,
                    isRefreshing: _isRefreshing,
                    onRefresh: () => _loadHistory(isRefresh: true),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabHeaderDelegate(
                  child: _HistoryTabBar(
                    tabController: _tabController,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _HistoryList(
                records: _donations,
                emptyTitle: 'Belum Ada Donasi',
                emptyDescription:
                    'Postingan makanan yang Anda buat akan muncul di sini.',
                mode: FoodDetailMode.donation,
                onDetail: (food) => _openDetail(food, FoodDetailMode.donation),
                onEdit: _openEdit,
                onDelete: _deleteFood,
              ),
              _HistoryList(
                records: _claims,
                emptyTitle: 'Belum Ada Klaim',
                emptyDescription:
                    'Makanan yang Anda klaim akan muncul di riwayat ini.',
                mode: FoodDetailMode.claim,
                onDetail: (food) => _openDetail(food, FoodDetailMode.claim),
                onEdit: null,
                onDelete: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int donationCount;
  final int claimCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _HistoryHeader({
    required this.donationCount,
    required this.claimCount,
    required this.isRefreshing,
    required this.onRefresh,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Aktivitas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelola donasi dan pantau klaim makanan.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Donasi',
                    value: '$donationCount',
                    icon: Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _SummaryTile(
                    label: 'Klaim',
                    value: '$claimCount',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTabBar extends StatelessWidget {
  final TabController tabController;

  const _HistoryTabBar({
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          AppSpacing.x1,
          AppSpacing.x3,
          AppSpacing.x1,
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppShadows.brand,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.primaryDark,
            labelStyle: Theme.of(context).textTheme.labelLarge,
            unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
            tabs: const [
              Tab(text: 'Donasi Saya'),
              Tab(text: 'Klaim Saya'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _TabHeaderDelegate({
    required this.child,
  });

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _HistoryList extends StatelessWidget {
  final List<FoodRecord> records;
  final String emptyTitle;
  final String emptyDescription;
  final FoodDetailMode mode;
  final ValueChanged<FoodRecord> onDetail;
  final ValueChanged<FoodRecord>? onEdit;
  final ValueChanged<FoodRecord>? onDelete;

  const _HistoryList({
    required this.records,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.mode,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _EmptyHistoryState(
        title: emptyTitle,
        description: emptyDescription,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        96,
      ),
      itemCount: records.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: AppSpacing.x2);
      },
      itemBuilder: (context, index) {
        final FoodRecord food = records[index];

        return _HistoryFoodCard(
          food: food,
          mode: mode,
          onDetail: () => onDetail(food),
          onEdit: onEdit == null ? null : () => onEdit!(food),
          onDelete: onDelete == null ? null : () => onDelete!(food),
        );
      },
    );
  }
}

class _HistoryFoodCard extends StatelessWidget {
  final FoodRecord food;
  final FoodDetailMode mode;
  final VoidCallback onDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _HistoryFoodCard({
    required this.food,
    required this.mode,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isDonationMode => mode == FoodDetailMode.donation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onDetail,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _FoodThumbnail(
                      imageUrl: food.photoUrl,
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusPill(
                            label: food.statusLabel,
                            color: _statusColor(food.status),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            food.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfo(
                        icon: Icons.inventory_2_outlined,
                        label: '${food.quantity} porsi',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x1),
                    Expanded(
                      child: _MiniInfo(
                        icon: Icons.schedule_rounded,
                        label: food.expiredAtLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                if (_isDonationMode)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDetail,
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Detail'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: food.isEditable ? onEdit : null,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      IconButton.filledTonal(
                        onPressed: food.isDeleteAllowed ? onDelete : null,
                        color: AppColors.danger,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onDetail,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Lihat Detail Klaim'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ON_THE_WAY':
        return AppColors.teal;
      case 'PICKED_UP':
        return AppColors.textMuted;
      case 'CANCELED':
        return AppColors.danger;
      case 'POSTED':
      case 'AVAILABLE':
      default:
        return AppColors.primary;
    }
  }
}

class _FoodThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _FoodThumbnail({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.accent,
        size: 34,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Image.network(
        imageUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
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

class _EmptyHistoryState extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyHistoryState({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x3),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(
                    Icons.inbox_outlined,
                    color: AppColors.textSecondary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySkeletonPage extends StatelessWidget {
  const _HistorySkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              const _SkeletonBox(height: 176),
              const SizedBox(height: AppSpacing.x2),
              const _SkeletonBox(height: 56),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: AppSpacing.x2);
                  },
                  itemBuilder: (context, index) {
                    return const _SkeletonBox(height: 176);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}