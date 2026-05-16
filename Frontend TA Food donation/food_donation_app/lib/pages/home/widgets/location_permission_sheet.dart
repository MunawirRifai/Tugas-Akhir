
import 'package:flutter/material.dart';

class LocationPermissionSheet extends StatelessWidget {
  final VoidCallback onAllow;

  const LocationPermissionSheet({
    super.key,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Allow your location',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'We will need your location to give you better experience',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAllow,
                child: const Text('Ok Sure'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}