import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';

class AdminDashboardPage extends StatefulWidget {
  final String token;

  const AdminDashboardPage({
    super.key,
    this.token = '',
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isActionBusy = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _foods = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool isRefresh = false}) async {
    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    List<Map<String, dynamic>> users = [];
    List<Map<String, dynamic>> foods = [];
    Map<String, dynamic> stats = {};

    try {
      final Map<String, dynamic> dashboard =
          await AdminService.getDashboard(widget.token);

      final Map<String, dynamic> dashboardData =
          AdminService.mapOf(dashboard['data']);

      users = AdminService.listOf(
        _firstAvailableValue(
          dashboardData,
          [
            'users',
            'allUsers',
            'userList',
          ],
        ),
      );

      foods = AdminService.listOf(
        _firstAvailableValue(
          dashboardData,
          [
            'foods',
            'allFoods',
            'foodList',
            'donations',
          ],
        ),
      );

      stats = AdminService.mapOf(
        _firstAvailableValue(
          dashboardData,
          [
            'stats',
            'summary',
            'dashboard',
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showSnack(
          'Dashboard utama gagal dimuat: $error',
          isError: true,
        );
      }
    }

    try {
      if (users.isEmpty) {
        users = await AdminService.getUsers(widget.token);
      }
    } catch (error) {
      debugPrint('ADMIN USERS ERROR: $error');
    }

    try {
      if (foods.isEmpty) {
        foods = await AdminService.getFoods(widget.token);
      }
    } catch (error) {
      debugPrint('ADMIN FOODS ERROR: $error');
    }

    if (!mounted) return;

    setState(() {
      _users = users;
      _foods = foods;
      _stats = stats;
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Object? _firstAvailableValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  Future<void> _deleteFood(Map<String, dynamic> food) async {
    final FoodRecord record = FoodRecord(food);
    final int? foodId = record.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    final bool? confirmed = await _showConfirmDialog(
      title: 'Hapus Postingan?',
      message:
          'Postingan "${record.name}" akan dihapus dari sistem. Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus',
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isActionBusy = true;
    });

    try {
      await AdminService.deleteFood(
        token: widget.token,
        foodId: foodId,
      );

      if (!mounted) return;

      _showSnack(
        'Postingan berhasil dihapus.',
        isError: false,
      );

      await _loadDashboard(isRefresh: true);
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menghapus postingan: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    setState(() {
      _isActionBusy = false;
    });
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final int? userId = AdminService.intOf(
      _valueOf(
        user,
        [
          'id',
          'user_id',
          'userId',
        ],
      ),
    );

    if (userId == null) {
      _showSnack(
        'ID user tidak valid.',
        isError: true,
      );
      return;
    }

    final String userName = _userName(user);

    final bool? confirmed = await _showConfirmDialog(
      title: 'Hapus User?',
      message:
          'User "$userName" akan dihapus dari sistem. Gunakan aksi ini hanya untuk data testing.',
      confirmLabel: 'Hapus',
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isActionBusy = true;
    });

    try {
      await AdminService.deleteUser(
        token: widget.token,
        userId: userId,
      );

      if (!mounted) return;

      _showSnack(
        'User berhasil dihapus.',
        isError: false,
      );

      await _loadDashboard(isRefresh: true);
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menghapus user: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    setState(() {
      _isActionBusy = false;
    });
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: Text(title),
          content: Text(message),
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
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AdminUserDetailSheet(
          user: user,
          onDelete: () {
            Navigator.of(context).pop();
            _deleteUser(user);
          },
        );
      },
    );
  }

  void _showFoodDetail(Map<String, dynamic> food) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AdminFoodDetailSheet(
          food: food,
          onDelete: () {
            Navigator.of(context).pop();
            _deleteFood(food);
          },
        );
      },
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

  int get _totalUsers {
    return AdminService.intOf(
          _valueOf(
            _stats,
            [
              'totalUsers',
              'users',
              'userCount',
            ],
          ),
        ) ??
        _users.length;
  }

  int get _totalFoods {
    return AdminService.intOf(
          _valueOf(
            _stats,
            [
              'totalFoods',
              'foods',
              'foodCount',
              'totalDonations',
            ],
          ),
        ) ??
        _foods.length;
  }

  int get _activeFoods {
    return _foods.where((food) {
      final FoodRecord record = FoodRecord(food);
      return record.status == 'POSTED' || record.status == 'AVAILABLE';
    }).length;
  }

  int get _completedFoods {
    return _foods.where((food) {
      final FoodRecord record = FoodRecord(food);
      return record.status == 'PICKED_UP';
    }).length;
  }

  int get _inProgressFoods {
    return _foods.where((food) {
      final FoodRecord record = FoodRecord(food);
      return record.status == 'ON_THE_WAY';
    }).length;
  }

  Object? _valueOf(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  String _userName(Map<String, dynamic> user) {
    return AdminService.textOf(
      _valueOf(
        user,
        [
          'fullName',
          'full_name',
          'name',
          'username',
        ],
      ),
      fallback: 'User',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _AdminSkeletonPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x3,
                AppSpacing.x2,
                AppSpacing.x3,
                AppSpacing.x1,
              ),
              child: _AdminHeader(
                totalUsers: _totalUsers,
                totalFoods: _totalFoods,
                activeFoods: _activeFoods,
                isRefreshing: _isRefreshing,
                onRefresh: () => _loadDashboard(isRefresh: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x3,
                AppSpacing.x1,
                AppSpacing.x3,
                AppSpacing.x2,
              ),
              child: _AdminTabBar(
                tabController: _tabController,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    totalUsers: _totalUsers,
                    totalFoods: _totalFoods,
                    activeFoods: _activeFoods,
                    inProgressFoods: _inProgressFoods,
                    completedFoods: _completedFoods,
                  ),
                  _UsersTab(
                    users: _users,
                    isActionBusy: _isActionBusy,
                    onTapUser: _showUserDetail,
                    onDeleteUser: _deleteUser,
                  ),
                  _FoodsTab(
                    foods: _foods,
                    isActionBusy: _isActionBusy,
                    onTapFood: _showFoodDetail,
                    onDeleteFood: _deleteFood,
                  ),
                  const _NetworkTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final int totalUsers;
  final int totalFoods;
  final int activeFoods;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _AdminHeader({
    required this.totalUsers,
    required this.totalFoods,
    required this.activeFoods,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brand,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitoring user, makanan, dan indikator jaringan.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                Expanded(
                  child: _AdminHeaderMetric(
                    label: 'User',
                    value: '$totalUsers',
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _AdminHeaderMetric(
                    label: 'Donasi',
                    value: '$totalFoods',
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _AdminHeaderMetric(
                    label: 'Aktif',
                    value: '$activeFoods',
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

class _AdminHeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _AdminHeaderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminTabBar extends StatelessWidget {
  final TabController tabController;

  const _AdminTabBar({
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'User'),
          Tab(text: 'Makanan'),
          Tab(text: 'Network'),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final int totalUsers;
  final int totalFoods;
  final int activeFoods;
  final int inProgressFoods;
  final int completedFoods;

  const _OverviewTab({
    required this.totalUsers,
    required this.totalFoods,
    required this.activeFoods,
    required this.inProgressFoods,
    required this.completedFoods,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x1,
        AppSpacing.x3,
        96,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_alt_outlined,
                label: 'Total User',
                value: '$totalUsers',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: _StatCard(
                icon: Icons.fastfood_rounded,
                label: 'Postingan',
                value: '$totalFoods',
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Tersedia',
                value: '$activeFoods',
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: _StatCard(
                icon: Icons.delivery_dining_rounded,
                label: 'Diproses',
                value: '$inProgressFoods',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        _StatusSummaryCard(
          activeFoods: activeFoods,
          inProgressFoods: inProgressFoods,
          completedFoods: completedFoods,
        ),
        const SizedBox(height: AppSpacing.x2),
        const _SecurityInsightCard(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

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
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  final int activeFoods;
  final int inProgressFoods;
  final int completedFoods;

  const _StatusSummaryCard({
    required this.activeFoods,
    required this.inProgressFoods,
    required this.completedFoods,
  });

  @override
  Widget build(BuildContext context) {
    final int total = activeFoods + inProgressFoods + completedFoods;
    final double activeRatio = total == 0 ? 0 : activeFoods / total;
    final double inProgressRatio = total == 0 ? 0 : inProgressFoods / total;
    final double completedRatio = total == 0 ? 0 : completedFoods / total;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Distribusi Status Donasi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Ringkasan performa operasional postingan makanan.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            _ProgressRow(
              label: 'Tersedia',
              value: activeFoods,
              ratio: activeRatio,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.x1),
            _ProgressRow(
              label: 'Sedang Diambil',
              value: inProgressFoods,
              ratio: inProgressRatio,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.x1),
            _ProgressRow(
              label: 'Selesai',
              value: completedFoods,
              ratio: completedRatio,
              color: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final double ratio;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: ratio,
              backgroundColor: AppColors.surfaceSoft,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                ),
          ),
        ),
      ],
    );
  }
}

class _SecurityInsightCard extends StatelessWidget {
  const _SecurityInsightCard();

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
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Insight Keamanan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.x2),
            const _InsightItem(
              icon: Icons.verified_user_outlined,
              title: 'Bearer Token',
              description:
                  'Request admin memakai Authorization header untuk kontrol akses.',
            ),
            const SizedBox(height: AppSpacing.x1),
            const _InsightItem(
              icon: Icons.lock_outline_rounded,
              title: 'Single User Entity',
              description:
                  'Satu akun user dapat dipantau sebagai donatur dan konsumen.',
            ),
            const SizedBox(height: AppSpacing.x1),
            const _InsightItem(
              icon: Icons.network_check_rounded,
              title: 'Network Metrics',
              description:
                  'Dashboard disiapkan untuk analisis bandwidth, latensi, dan performa.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool isActionBusy;
  final ValueChanged<Map<String, dynamic>> onTapUser;
  final ValueChanged<Map<String, dynamic>> onDeleteUser;

  const _UsersTab({
    required this.users,
    required this.isActionBusy,
    required this.onTapUser,
    required this.onDeleteUser,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyAdminState(
        icon: Icons.people_outline_rounded,
        title: 'Belum Ada User',
        description: 'Data user belum tersedia dari backend.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x1,
        AppSpacing.x3,
        96,
      ),
      itemCount: users.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: AppSpacing.x2);
      },
      itemBuilder: (context, index) {
        final Map<String, dynamic> user = users[index];

        return _UserCard(
          user: user,
          isActionBusy: isActionBusy,
          onTap: () => onTapUser(user),
          onDelete: () => onDeleteUser(user),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isActionBusy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isActionBusy,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = AdminService.textOf(
      _valueOf(
        user,
        [
          'fullName',
          'full_name',
          'name',
          'username',
        ],
      ),
      fallback: 'User',
    );

    final String email = AdminService.textOf(
      _valueOf(
        user,
        [
          'email',
          'userEmail',
        ],
      ),
      fallback: 'Email tidak tersedia',
    );

    final String role = AdminService.textOf(
      _valueOf(
        user,
        [
          'role',
          'userRole',
        ],
      ),
      fallback: 'USER',
    ).toUpperCase();

    return _AdminListCard(
      onTap: onTap,
      leading: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.primaryDark,
        ),
      ),
      title: name,
      subtitle: email,
      badgeLabel: role,
      badgeColor: role == 'ADMIN' ? AppColors.accent : AppColors.primary,
      trailing: IconButton(
        onPressed: isActionBusy ? null : onDelete,
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
    );
  }

  Object? _valueOf(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }
}

class _FoodsTab extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  final bool isActionBusy;
  final ValueChanged<Map<String, dynamic>> onTapFood;
  final ValueChanged<Map<String, dynamic>> onDeleteFood;

  const _FoodsTab({
    required this.foods,
    required this.isActionBusy,
    required this.onTapFood,
    required this.onDeleteFood,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return const _EmptyAdminState(
        icon: Icons.fastfood_rounded,
        title: 'Belum Ada Postingan',
        description: 'Data postingan makanan belum tersedia dari backend.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x1,
        AppSpacing.x3,
        96,
      ),
      itemCount: foods.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: AppSpacing.x2);
      },
      itemBuilder: (context, index) {
        final Map<String, dynamic> food = foods[index];

        return _FoodCard(
          food: food,
          isActionBusy: isActionBusy,
          onTap: () => onTapFood(food),
          onDelete: () => onDeleteFood(food),
        );
      },
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final bool isActionBusy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FoodCard({
    required this.food,
    required this.isActionBusy,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final FoodRecord record = FoodRecord(food);

    return _AdminListCard(
      onTap: onTap,
      leading: _FoodThumbnail(
        imageUrl: record.photoUrl,
      ),
      title: record.name,
      subtitle: '${record.quantity} porsi • ${record.address}',
      badgeLabel: record.statusLabel,
      badgeColor: _statusColor(record.status),
      trailing: IconButton(
        onPressed: isActionBusy ? null : onDelete,
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
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

class _AdminListCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final Widget trailing;
  final VoidCallback onTap;

  const _AdminListCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.trailing,
    required this.onTap,
  });

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusPill(
                        label: badgeLabel,
                        color: badgeColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
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
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.accent,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Image.network(
        imageUrl!,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _NetworkTab extends StatelessWidget {
  const _NetworkTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x1,
        AppSpacing.x3,
        96,
      ),
      children: const [
        _NetworkMetricCard(
          icon: Icons.speed_rounded,
          title: 'Estimasi Performa',
          description:
              'UI disiapkan untuk mencatat latency, response time, dan throughput request API.',
          metricOneLabel: 'Latency',
          metricOneValue: '± 42 ms',
          metricTwoLabel: 'Response',
          metricTwoValue: '± 180 ms',
        ),
        SizedBox(height: AppSpacing.x2),
        _NetworkMetricCard(
          icon: Icons.network_check_rounded,
          title: 'Bandwidth Upload',
          description:
              'Image optimizer menyimpan estimasi ukuran asli dan estimasi payload upload.',
          metricOneLabel: 'Image',
          metricOneValue: 'Simulasi',
          metricTwoLabel: 'Payload',
          metricTwoValue: 'Tercatat',
        ),
        SizedBox(height: AppSpacing.x2),
        _NetworkMetricCard(
          icon: Icons.call_outlined,
          title: 'In-App VoIP',
          description:
              'Audio/video call memakai mockup frontend sebagai bahan analisis komunikasi in-app.',
          metricOneLabel: 'Audio',
          metricOneValue: '64 kbps',
          metricTwoLabel: 'Video',
          metricTwoValue: '900 kbps',
        ),
      ],
    );
  }
}

class _NetworkMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String metricOneLabel;
  final String metricOneValue;
  final String metricTwoLabel;
  final String metricTwoValue;

  const _NetworkMetricCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.metricOneLabel,
    required this.metricOneValue,
    required this.metricTwoLabel,
    required this.metricTwoValue,
  });

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
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              icon,
              color: AppColors.primaryDark,
              size: 34,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: _SmallMetric(
                    label: metricOneLabel,
                    value: metricOneValue,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _SmallMetric(
                    label: metricTwoLabel,
                    value: metricTwoValue,
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

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SmallMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDelete;

  const _AdminUserDetailSheet({
    required this.user,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = AdminService.textOf(
      _valueOf(user, ['fullName', 'full_name', 'name', 'username']),
      fallback: 'User',
    );

    final String email = AdminService.textOf(
      _valueOf(user, ['email']),
      fallback: 'Email tidak tersedia',
    );

    final String phone = AdminService.textOf(
      _valueOf(user, ['phone', 'phone_number', 'mobile']),
      fallback: 'Nomor tidak tersedia',
    );

    final String createdAt = AdminService.dateLabel(
      _valueOf(user, ['created_at', 'createdAt']),
    );

    return _AdminSheet(
      title: 'Detail User',
      icon: Icons.person_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetInfoRow(label: 'Nama', value: name),
          _SheetInfoRow(label: 'Email', value: email),
          _SheetInfoRow(label: 'Kontak', value: phone),
          _SheetInfoRow(label: 'Terdaftar', value: createdAt),
          const SizedBox(height: AppSpacing.x3),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus User'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Object? _valueOf(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }
}

class _AdminFoodDetailSheet extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onDelete;

  const _AdminFoodDetailSheet({
    required this.food,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final FoodRecord record = FoodRecord(food);

    return _AdminSheet(
      title: 'Detail Postingan',
      icon: Icons.fastfood_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetInfoRow(label: 'Makanan', value: record.name),
          _SheetInfoRow(label: 'Status', value: record.statusLabel),
          _SheetInfoRow(label: 'Jumlah', value: '${record.quantity} porsi'),
          _SheetInfoRow(label: 'Lokasi', value: record.address),
          _SheetInfoRow(label: 'Expired', value: record.expiredAtLabel),
          const SizedBox(height: AppSpacing.x3),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus Postingan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AdminSheet({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SheetInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyAdminState({
    required this.icon,
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
                Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: 52,
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

class _AdminSkeletonPage extends StatelessWidget {
  const _AdminSkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              const _SkeletonBox(height: 216),
              const SizedBox(height: AppSpacing.x2),
              const _SkeletonBox(height: 54),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: AppSpacing.x2);
                  },
                  itemBuilder: (context, index) {
                    return const _SkeletonBox(height: 132);
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