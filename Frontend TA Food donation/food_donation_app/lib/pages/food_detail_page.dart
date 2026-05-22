import 'package:flutter/material.dart';

import '../services/food_service.dart';
import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';
import 'call_page.dart';
import 'chat_room_page.dart';
import 'edit_food_page.dart';

enum FoodDetailMode {
  donation,
  claim,
  public,
}

class FoodDetailPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> food;
  final FoodDetailMode mode;

  const FoodDetailPage({
    super.key,
    required this.token,
    required this.food,
    this.mode = FoodDetailMode.public,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late Map<String, dynamic> _foodData;

  bool _isDeleting = false;

  FoodRecord get _food => FoodRecord(_foodData);

  bool get _isDonationMode => widget.mode == FoodDetailMode.donation;

  String get _counterpartName {
    switch (widget.mode) {
      case FoodDetailMode.donation:
        return 'Konsumen';
      case FoodDetailMode.claim:
        return 'Donatur';
      case FoodDetailMode.public:
        return 'Pengguna';
    }
  }

  @override
  void initState() {
    super.initState();
    _foodData = Map<String, dynamic>.from(widget.food);
  }

  Future<void> _openEditPage() async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditFoodPage(
          token: widget.token,
          food: _food.toMap(),
        ),
      ),
    );

    if (updated != true) return;
    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  Future<void> _deleteFood() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: const Text('Hapus Postingan?'),
          content: Text(
            'Postingan "${_food.name}" akan dihapus permanen.',
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
    if (!mounted) return;

    final int? foodId = _food.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

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

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal menghapus postingan: $error',
        isError: true,
      );

      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _openChatRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          token: widget.token,
          food: _food.toMap(),
          counterpartName: _counterpartName,
        ),
      ),
    );
  }

  void _openCall(InAppCallType callType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallPage(
          token: widget.token,
          food: _food.toMap(),
          counterpartName: _counterpartName,
          callType: callType,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final FoodRecord food = _food;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Makanan'),
        actions: [
          if (_isDonationMode && food.isEditable)
            IconButton(
              onPressed: _isDeleting ? null : _openEditPage,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (_isDonationMode && food.isDeleteAllowed)
            IconButton(
              onPressed: _isDeleting ? null : _deleteFood,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            AppSpacing.x4,
          ),
          children: [
            _FoodHeroImage(
              imageUrl: food.photoUrl,
            ),
            const SizedBox(height: AppSpacing.x3),
            _TitleSection(
              food: food,
              mode: widget.mode,
            ),
            const SizedBox(height: AppSpacing.x2),
            _MetricGrid(
              food: food,
            ),
            const SizedBox(height: AppSpacing.x2),
            _InfoCard(
              icon: Icons.notes_rounded,
              title: 'Deskripsi',
              description: food.description,
            ),
            const SizedBox(height: AppSpacing.x2),
            _InfoCard(
              icon: Icons.place_outlined,
              title: 'Lokasi Pickup',
              description: '${food.address}\n${food.coordinateLabel}',
            ),
            const SizedBox(height: AppSpacing.x2),
            _CommunicationCard(
              onChat: _openChatRoom,
              onAudio: () => _openCall(InAppCallType.audio),
              onVideo: () => _openCall(InAppCallType.video),
            ),
            const SizedBox(height: AppSpacing.x2),
            if (_isDonationMode)
              _DonationManagementCard(
                food: food,
                isDeleting: _isDeleting,
                onEdit: food.isEditable ? _openEditPage : null,
                onDelete: food.isDeleteAllowed ? _deleteFood : null,
              )
            else
              _ClaimInfoCard(
                statusLabel: food.statusLabel,
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodHeroImage extends StatelessWidget {
  final String? imageUrl;

  const _FoodHeroImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.accent,
        size: 68,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Image.network(
        imageUrl!,
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final FoodRecord food;
  final FoodDetailMode mode;

  const _TitleSection({
    required this.food,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDonation = mode == FoodDetailMode.donation;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusPill(
              label: food.statusLabel,
              color: _statusColor(food.status),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              food.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              isDonation
                  ? 'Postingan donasi milik Anda.'
                  : 'Riwayat klaim makanan Anda.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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

class _MetricGrid extends StatelessWidget {
  final FoodRecord food;

  const _MetricGrid({
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.inventory_2_outlined,
            label: 'Jumlah',
            value: '${food.quantity} porsi',
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: _MetricTile(
            icon: Icons.schedule_rounded,
            label: 'Batas',
            value: food.expiredAtLabel,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunicationCard extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onAudio;
  final VoidCallback onVideo;

  const _CommunicationCard({
    required this.onChat,
    required this.onAudio,
    required this.onVideo,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Komunikasi In-App',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Frontend mockup untuk chat dan VoIP tanpa nomor telepon seluler.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAudio,
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Audio'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
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

class _DonationManagementCard extends StatelessWidget {
  final FoodRecord food;
  final bool isDeleting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DonationManagementCard({
    required this.food,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
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
            Text(
              'Manajemen Postingan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Edit atau hapus postingan donasi makanan milik Anda.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDeleting ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDeleting ? null : onDelete,
                    icon: isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus'),
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

class _ClaimInfoCard extends StatelessWidget {
  final String statusLabel;

  const _ClaimInfoCard({
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Row(
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                'Status klaim saat ini: $statusLabel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                    ),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}