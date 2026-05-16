import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String token;

  const DashboardPage({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF137A3D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login Berhasil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Access Token:'),
            const SizedBox(height: 8),
            SelectableText(token),
          ],
        ),
      ),
    );
  }
}