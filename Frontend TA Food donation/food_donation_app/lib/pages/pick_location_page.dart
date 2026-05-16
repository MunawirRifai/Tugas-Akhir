import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickLocationPage extends StatefulWidget {
  final LatLng initialLocation;

  const PickLocationPage({
    super.key,
    required this.initialLocation,
  });

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  late LatLng selectedLocation;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: selectedLocation,
          initialZoom: 16,
          onTap: (_, point) {
            setState(() {
              selectedLocation = point;
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
                point: selectedLocation,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, selectedLocation);
        },
        label: const Text('Pilih'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}