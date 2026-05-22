import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'add_food_page.dart';
import 'history_page.dart';
import 'home/widgets/bottom_nav_bar.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  final String token;

  const MainNavigationPage({
    super.key,
    required this.token,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  int _homeRefreshKey = 0;

  void _changeTab(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _openAddFoodPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFoodPage(token: widget.token),
      ),
    );

    if (!mounted) return;

    setState(() {
      _selectedIndex = 0;
      _homeRefreshKey++;
    });
  }

  List<Widget> _buildPages() {
    return [
      HomePage(
        key: ValueKey('home-$_homeRefreshKey'),
        token: widget.token,
      ),
      HistoryPage(token: widget.token),
      NotificationPage(token: widget.token),
      ProfilePage(token: widget.token),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildPages(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah donasi makanan',
        onPressed: _openAddFoodPage,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _selectedIndex,
        onChanged: _changeTab,
      ),
    );
  }
}