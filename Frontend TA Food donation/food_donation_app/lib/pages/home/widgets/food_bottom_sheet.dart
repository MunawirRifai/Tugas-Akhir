import 'package:flutter/material.dart';
import 'package:food_donation_app/pages/history_page.dart';
import 'package:food_donation_app/pages/profile_page.dart';

class HomeBottomNavBar extends StatelessWidget {
  final String token;

  const HomeBottomNavBar({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.home_outlined)),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPage(token: token),
                ),
              );
            },
            icon: const Icon(Icons.access_time_outlined),
          ),
          const SizedBox(width: 40),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(token: token),
                ),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
    );
  }
}