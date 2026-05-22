import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const String _onboardingStorageKey = 'has_seen_onboarding_v1';

  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _isFinishing = false;

  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      title: 'Berbagi Tanpa Sisa',
      description:
          'Donatur dapat membagikan makanan layak konsumsi dengan proses posting yang cepat dan jelas.',
      badge: 'Donasi real-time',
      icon: Icons.restaurant_rounded,
      color: AppColors.primary,
    ),
    _OnboardingItem(
      title: 'Klaim Lebih Cepat',
      description:
          'Konsumen dapat melihat makanan terdekat, jarak lokasi, dan status ketersediaan secara ringkas.',
      badge: 'Radius lokasi',
      icon: Icons.near_me_rounded,
      color: AppColors.teal,
    ),
    _OnboardingItem(
      title: 'Aman dan Terukur',
      description:
          'Alur aplikasi disiapkan untuk analisis keamanan, bandwidth, dan performa jaringan.',
      badge: 'Network-ready',
      icon: Icons.security_rounded,
      color: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(_onboardingStorageKey, true);

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<void> _goNext() async {
    if (_currentPage >= _items.length - 1) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            children: [
              _OnboardingHeader(
                isDisabled: _isFinishing,
                onSkip: _finishOnboarding,
              ),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingSlide(
                      item: _items[index],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              _PageIndicator(
                length: _items.length,
                activeIndex: _currentPage,
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFinishing ? null : _goNext,
                  child: _isFinishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLastPage ? 'Mulai Sekarang' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onSkip;

  const _OnboardingHeader({
    required this.isDisabled,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'FoodShare',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: isDisabled ? null : onSkip,
          child: const Text('Lewati'),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingItem item;

  const _OnboardingSlide({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double illustrationHeight = math.min(
          300,
          math.max(220, constraints.maxHeight * 0.46),
        );

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: illustrationHeight,
                  width: double.infinity,
                  child: _PremiumIllustration(item: item),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumIllustration extends StatelessWidget {
  final _OnboardingItem item;

  const _PremiumIllustration({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxHeight < 250;
        final double iconBoxSize = isCompact ? 72 : 88;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.x3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -32,
                right: -24,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -36,
                left: -28,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: isCompact ? 34 : 42,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _MockFoodCard(
                      badge: item.badge,
                      color: item.color,
                      isCompact: isCompact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MockFoodCard extends StatelessWidget {
  final String badge;
  final Color color;
  final bool isCompact;

  const _MockFoodCard({
    required this.badge,
    required this.color,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 230 : 270,
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paket Makanan Siap Klaim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int length;
  final int activeIndex;

  const _PageIndicator({
    required this.length,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final bool isActive = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final Color color;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.color,
  });
}