
import 'package:flutter/material.dart';

class PickupBar extends StatelessWidget {
  final dynamic selectedFood;
  final int? currentUserId;
  final VoidCallback onClose;
  final VoidCallback? onPickNow;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const PickupBar({
    super.key,
    required this.selectedFood,
    required this.currentUserId,
    required this.onClose,
    this.onPickNow,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 90,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedFood['food_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedFood['status'] == 'ON_THE_WAY'
                          ? (selectedFood['claimed_by'] == currentUserId
                              ? 'Kamu sedang mengambil makanan ini'
                              : 'Makanan ini sedang diambil orang lain')
                          : 'Rute ke lokasi makanan sudah ditampilkan',
                    ),
                  ],
                ),
              ),
              if (selectedFood['status'] == 'POSTED')
                ElevatedButton(
                  onPressed: onPickNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ambil Sekarang'),
                )
              else if (selectedFood['status'] == 'ON_THE_WAY' &&
                  selectedFood['claimed_by'] == currentUserId)
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Makanan Telah Diambil'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}