import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class PickLocationPage extends StatefulWidget {
  final LatLng initialLocation;

  const PickLocationPage({super.key, required this.initialLocation});

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  final MapController _mapController = MapController();

  late LatLng _selectedLocation;

  bool _isFindingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isFindingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          _isFindingLocation = false;
        });

        _showSnack('Location service belum aktif.', isError: true);

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isFindingLocation = false;
        });

        _showSnack('Izin lokasi belum diberikan.', isError: true);

        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      final LatLng currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLocation = currentLocation;
        _isFindingLocation = false;
      });

      _mapController.move(currentLocation, 16);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isFindingLocation = false;
      });

      _showSnack('Gagal membaca lokasi saat ini: $error', isError: true);
    }
  }

  void _confirmLocation() {
    Navigator.of(context).pop(_selectedLocation);
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  String get _coordinateText {
    return '${_selectedLocation.latitude.toStringAsFixed(6)}, '
        '${_selectedLocation.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          TextButton(onPressed: _confirmLocation, child: const Text('Pilih')),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 16,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.food_donation_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 72,
                    height: 72,
                    point: _selectedLocation,
                    child: const _LocationPin(),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: _InstructionCard(coordinateText: _coordinateText),
            ),
          ),
          Positioned(
            left: AppSpacing.x2,
            right: AppSpacing.x2,
            bottom: AppSpacing.x2,
            child: SafeArea(
              top: false,
              child: _LocationActionPanel(
                coordinateText: _coordinateText,
                isFindingLocation: _isFindingLocation,
                onUseCurrentLocation: _useCurrentLocation,
                onConfirm: _confirmLocation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String coordinateText;

  const _InstructionCard({required this.coordinateText});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap peta untuk memilih titik',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coordinateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _LocationActionPanel extends StatelessWidget {
  final String coordinateText;
  final bool isFindingLocation;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onConfirm;

  const _LocationActionPanel({
    required this.coordinateText,
    required this.isFindingLocation,
    required this.onUseCurrentLocation,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Koordinat Pickup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(coordinateText, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isFindingLocation ? null : onUseCurrentLocation,
                    icon: isFindingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: const Text('Lokasi Saya'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Pilih Titik'),
                    ),
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

class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppShadows.brand,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}
