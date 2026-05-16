import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:food_donation_app/pages/add_food_page.dart';
import 'package:food_donation_app/pages/history_page.dart';
import 'package:food_donation_app/pages/profile_page.dart';
import 'package:food_donation_app/services/auth_service.dart';
import 'package:food_donation_app/services/food_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  bool locationAllowed = false;

  LatLng currentLocation = const LatLng(-6.9730, 107.6300);

  List<dynamic> foods = [];
  int? currentUserId;

  LatLng? selectedDestination;
  List<LatLng> routePoints = [];

  bool showPickupBar = false;
  dynamic selectedFood;
  int claimQuantity = 1; // jumlah yang akan diklaim user

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    checkLocation();
    loadFoods();
    loadCurrentUser();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    });

    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadFoods();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadCurrentUser() async {
    try {
      final profile = await AuthService.getProfile(widget.token);

      setState(() {
        currentUserId = profile['data']['id'];
      });
    } catch (e) {
      debugPrint('LOAD CURRENT USER ERROR: $e');
    }
  }

  Future<void> checkLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        loading = false;
        locationAllowed = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        loading = false;
        locationAllowed = false;
      });

      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);

      locationAllowed = true;
      loading = false;
    });
  }

  Future<void> requestLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      locationAllowed = true;
    });
  }

  Future<void> loadFoods() async {
    try {
      final result = await FoodService.getFoods(widget.token);

      setState(() {
        foods = result;
      });
    } catch (e) {
      debugPrint('LOAD FOOD ERROR: $e');
    }
  }

  Future<void> showRoute(double latitude, double longitude) async {
    selectedDestination = LatLng(latitude, longitude);

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${currentLocation.longitude},${currentLocation.latitude};'
      '$longitude,$latitude?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

      setState(() {
        routePoints = coordinates
            .map(
              (point) => LatLng(
                (point[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ),
            )
            .toList();
      });
    }
  }

  /// Format string ISO 8601 menjadi tampilan lebih ramah
  String _formatExpiredAt(String? isoString) {
    if (isoString == null) return '-';
    try {
      final dt = DateTime.parse(isoString);
      final pad = (int n) => n.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
    } catch (_) {
      return isoString;
    }
  }

  /// Widget stepper untuk memilih jumlah klaim sebelum mengambil
  Widget _buildClaimSection(dynamic food) {
    final int maxQty = (food['quantity'] as num?)?.toInt() ?? 1;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah yang ingin diambil:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol minus
                IconButton(
                  onPressed: claimQuantity > 1
                      ? () {
                          setLocalState(() => claimQuantity--);
                          setState(() {});
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.green,
                  iconSize: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  '$claimQuantity',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / $maxQty',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                // Tombol plus
                IconButton(
                  onPressed: claimQuantity < maxQty
                      ? () {
                          setLocalState(() => claimQuantity++);
                          setState(() {});
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  await showRoute(
                    (food['latitude'] as num).toDouble(),
                    (food['longitude'] as num).toDouble(),
                  );

                  if (!mounted) return;

                  setState(() {
                    selectedFood = food;
                    showPickupBar = true;
                  });
                },
                icon: const Icon(Icons.alt_route),
                label: Text('Lihat Rute ($claimQuantity porsi)'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.food_donation_app',
              ),

              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: currentLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 35,
                    ),
                  ),

                  if (selectedDestination != null && selectedFood != null)
                    Marker(
                      width: 60,
                      height: 60,
                      point: selectedDestination!,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              return Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.8,
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(
                                    context,
                                  ).viewInsets.bottom,
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedFood['food_name'],
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                await FoodService.confirmPickup(
                                                  token: widget.token,
                                                  foodId: selectedFood['id'],
                                                );

                                                if (!context.mounted) return;
                                                Navigator.pop(context);

                                                setState(() {
                                                  routePoints.clear();
                                                  selectedDestination = null;
                                                  selectedFood = null;
                                                });

                                                await loadFoods();
                                              },
                                              icon: const Icon(Icons.check),
                                              label: const Text(
                                                'Makanan Telah Diambil',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                await FoodService.cancelPickup(
                                                  token: widget.token,
                                                  foodId: selectedFood['id'],
                                                );

                                                if (!context.mounted) return;
                                                Navigator.pop(context);

                                                setState(() {
                                                  routePoints.clear();
                                                  selectedDestination = null;
                                                  selectedFood = null;
                                                });

                                                await loadFoods();
                                              },
                                              icon: const Icon(Icons.close),
                                              label: const Text('Cancel'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                  ...foods
                      .where((food) {
                        if (food['status'] == 'PICKED_UP') return false;
                        return true;
                      })
                      .map(
                        (food) => Marker(
                          width: 60,
                          height: 60,
                          point: LatLng(
                            (food['latitude'] as num).toDouble(),
                            (food['longitude'] as num).toDouble(),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (_) {
                                  final int foodUserId = int.parse(
                                    food['user_id'].toString(),
                                  );

                                  final bool isOwner =
                                      currentUserId != null &&
                                      foodUserId == currentUserId;

                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.8,
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(
                                        context,
                                      ).viewInsets.bottom,
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.network(
                                              food['photo_url'] ?? '',
                                              width: double.infinity,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: double.infinity,
                                                      height: 180,
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.fastfood,
                                                        size: 60,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            food['food_name'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(food['description'] ?? ''),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tersedia: ${food['quantity']} porsi',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (food['expired_at'] != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Batas: ${_formatExpiredAt(food['expired_at'])}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 20),
                                          if (isOwner)
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  await FoodService.deleteFood(
                                                    token: widget.token,
                                                    foodId: food['id'],
                                                  );
                                                  if (!context.mounted) return;
                                                  Navigator.pop(context);
                                                  await loadFoods();
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Post berhasil dibatalkan',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.delete),
                                                label: const Text('Batalkan'),
                                              ),
                                            )
                                          else if (food['status'] ==
                                                  'ON_THE_WAY' &&
                                              food['claimed_by'] ==
                                                  currentUserId)
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.amber,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  await showRoute(
                                                    (food['latitude'] as num)
                                                        .toDouble(),
                                                    (food['longitude'] as num)
                                                        .toDouble(),
                                                  );
                                                  setState(() {
                                                    selectedFood = food;
                                                    showPickupBar = true;
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.access_time,
                                                ),
                                                label: const Text(
                                                  'Lanjutkan Pengambilan',
                                                ),
                                              ),
                                            )
                                          else if (food['status'] == 'POSTED')
                                            _buildClaimSection(food),
                                          if (food['status'] == 'ON_THE_WAY' &&
                                              food['claimed_by'] !=
                                                  currentUserId)
                                            const SizedBox(
                                              width: double.infinity,
                                              child: Center(
                                                child: Text(
                                                  'Stok habis, sedang dalam pengambilan',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),

          if (showPickupBar && selectedFood != null)
            Positioned(
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
                        onPressed: () {
                          setState(() {
                            showPickupBar = false;
                            selectedFood = null;
                            selectedDestination = null;
                            routePoints.clear();
                          });
                        },
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedFood['status'] == 'ON_THE_WAY'
                                  ? (selectedFood['claimed_by'] == currentUserId
                                        ? 'Mengambil $claimQuantity porsi'
                                        : 'Stok habis, sedang dalam pengambilan')
                                  : 'Mengambil $claimQuantity dari ${selectedFood['quantity']} porsi',
                            ),
                          ],
                        ),
                      ),
                      if (selectedFood['status'] == 'POSTED') ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            try {
                              await FoodService.pickFood(
                                token: widget.token,
                                foodId: selectedFood['id'],
                                quantity: claimQuantity,
                              );

                              await loadFoods();

                              setState(() {
                                selectedFood = {
                                  ...selectedFood,
                                  'status': 'ON_THE_WAY',
                                  'claimed_by': currentUserId,
                                  'claimed_quantity': claimQuantity,
                                };
                              });
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Porsi makanan tidak cukup'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Ambil Sekarang'),
                        ),
                      ] else if (selectedFood['status'] == 'ON_THE_WAY' &&
                          selectedFood['claimed_by'] == currentUserId) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await FoodService.confirmPickup(
                              token: widget.token,
                              foodId: selectedFood['id'],
                            );

                            await loadFoods();

                            setState(() {
                              showPickupBar = false;
                              selectedFood = null;
                              selectedDestination = null;
                              routePoints.clear();
                            });
                          },
                          child: const Text('Makanan Telah Diambil'),
                        ),

                        const SizedBox(width: 8),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await FoodService.cancelPickup(
                              token: widget.token,
                              foodId: selectedFood['id'],
                            );

                            await loadFoods();

                            setState(() {
                              selectedFood = {
                                ...selectedFood,
                                'status': 'POSTED',
                                'claimed_by': null,
                              };

                              showPickupBar = false;
                              selectedDestination = null;
                              routePoints.clear();
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          if (!locationAllowed)
            Container(color: Colors.black.withValues(alpha: 0.4)),

          if (!locationAllowed)
            Align(
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Not Now'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: requestLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF98D8B0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Ok Sure'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
