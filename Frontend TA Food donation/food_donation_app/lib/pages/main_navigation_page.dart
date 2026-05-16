import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';
import 'add_food_page.dart';

class MainNavigationPage extends StatefulWidget {
  final String token;

  const MainNavigationPage({super.key, required this.token});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(token: widget.token),
      HistoryPage(token: widget.token),
      NotificationPage(token: widget.token),
      ProfilePage(token: widget.token),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFoodPage(token: widget.token),
            ),
          );
        },
        backgroundColor: const Color(0xFF0B6B3A),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Home
              MaterialButton(
                minWidth: 40,
                onPressed: () => _onItemTapped(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: _selectedIndex == 0 ? const Color(0xFF0B6B3A) : Colors.grey,
                    ),
                    if (_selectedIndex == 0)
                      Container(
                        height: 4,
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0B6B3A),
                          shape: BoxShape.circle,
                        ),
                      )
                  ],
                ),
              ),
              // History
              MaterialButton(
                minWidth: 40,
                onPressed: () => _onItemTapped(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      color: _selectedIndex == 1 ? const Color(0xFF0B6B3A) : Colors.grey,
                    ),
                    if (_selectedIndex == 1)
                      Container(
                        height: 4,
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0B6B3A),
                          shape: BoxShape.circle,
                        ),
                      )
                  ],
                ),
              ),
              
              // Gap for FAB
              const SizedBox(width: 40),

              // Notifications
              MaterialButton(
                minWidth: 40,
                onPressed: () => _onItemTapped(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: _selectedIndex == 2 ? const Color(0xFF0B6B3A) : Colors.grey,
                    ),
                    if (_selectedIndex == 2)
                      Container(
                        height: 4,
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0B6B3A),
                          shape: BoxShape.circle,
                        ),
                      )
                  ],
                ),
              ),
              // Profile
              MaterialButton(
                minWidth: 40,
                onPressed: () => _onItemTapped(3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: _selectedIndex == 3 ? const Color(0xFF0B6B3A) : Colors.grey,
                    ),
                    if (_selectedIndex == 3)
                      Container(
                        height: 4,
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0B6B3A),
                          shape: BoxShape.circle,
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
