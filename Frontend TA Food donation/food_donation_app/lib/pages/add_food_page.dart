import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/food_service.dart';
import 'pick_location_page.dart';

import 'package:latlong2/latlong.dart';

class AddFoodPage extends StatefulWidget {
  final String token;

  const AddFoodPage({super.key, required this.token});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final foodNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();

  XFile? image;
  int quantity = 1;

  double latitude = -6.9733;
  double longitude = 107.6300;

  // Batas waktu pengambilan: default 3 jam, max 6 jam dari sekarang
  DateTime _expiredAt = DateTime.now().add(const Duration(hours: 3));

  String get _expiredAtDisplay {
    final dt = _expiredAt;
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  Future<void> _pickExpiredAt() async {
    final now = DateTime.now();
    final maxTime = now.add(const Duration(hours: 6));

    // Pilih tanggal
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiredAt,
      firstDate: now,
      lastDate: maxTime,
      helpText: 'Pilih Tanggal Batas Waktu',
    );

    if (pickedDate == null) return;

    // Pilih waktu
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiredAt),
      helpText: 'Pilih Waktu Batas Pengambilan',
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validasi max 6 jam
    if (combined.isAfter(maxTime)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas waktu maksimal 6 jam dari sekarang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi tidak boleh di masa lalu
    if (combined.isBefore(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas waktu tidak boleh di masa lalu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _expiredAt = combined;
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  Future<void> useCurrentLocation() async {
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      addressController.text = '${position.latitude}, ${position.longitude}';
    });
  }

  Future<void> submit() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto terlebih dahulu')),
      );
      return;
    }

    if (foodNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama makanan tidak boleh kosong')),
      );
      return;
    }

    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi belum dipilih')),
      );
      return;
    }

    try {
      final response = await FoodService.createFood(
        token: widget.token,
        foodName: foodNameController.text,
        description: descriptionController.text,
        quantity: quantity,
        latitude: latitude,
        longitude: longitude,
        address: addressController.text,
        expiredAt: _expiredAt.toIso8601String(),
        image: image!,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Donasi berhasil diposting!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Lanjutkan'),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal memposting')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    foodNameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Donation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Foto ===
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 50),
                          SizedBox(height: 10),
                          Text('Tambah Foto'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(image!.path, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // === Nama Makanan ===
            TextField(
              controller: foodNameController,
              decoration: const InputDecoration(labelText: 'Food Name'),
            ),
            const SizedBox(height: 12),

            // === Deskripsi ===
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Food Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // === Batas Waktu Pengambilan ===
            const Text(
              'Batas Waktu Pengambilan',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickExpiredAt,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _expiredAtDisplay,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Maksimal 6 jam dari sekarang',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),

            // === Jumlah Makanan — Stepper ===
            const Text(
              'Jumlah Makanan',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol minus
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                    color: Colors.green,
                    iconSize: 28,
                  ),
                  // Angka
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Tombol plus
                  IconButton(
                    onPressed: () => setState(() => quantity++),
                    icon: const Icon(Icons.add),
                    color: Colors.green,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // === Lokasi ===
            TextField(
              controller: addressController,
              readOnly: true,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickLocationPage(
                      initialLocation: LatLng(latitude, longitude),
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    latitude = result.latitude;
                    longitude = result.longitude;
                    addressController.text =
                        '${result.latitude}, ${result.longitude}';
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Location',
                suffixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: useCurrentLocation,
                child: const Text('Gunakan Lokasi Saat Ini'),
              ),
            ),
            const SizedBox(height: 24),

            // === Tombol Post ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF98D8B0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Post', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
