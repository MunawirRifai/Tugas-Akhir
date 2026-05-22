import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';
import '../services/food_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_config.dart';
import 'home/services/route_service.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({
    super.key,
    required this.token,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();

  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionSubscription;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isActionBusy = false;
  bool _locationAllowed = false;

  int? _currentUserId;
  int _claimQuantity = 1;
  double _radiusMeters = 3000;

  LatLng _currentLocation = const LatLng(-6.9730, 107.6300);
  LatLng? _selectedDestination;

  List<dynamic> _foods = [];
  List<LatLng> _routePoints = [];

  Map<String, dynamic>? _selectedFood;

  @override
  void initState() {
    super.initState();

    _bootstrap();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) => _loadFoods(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _prepareLocation(),
      _loadCurrentUser(),
      _loadFoods(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _prepareLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          _locationAllowed = false;
        });
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
          _locationAllowed = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationAllowed = true;
      });

      _startLocationStream();
    } catch (error) {
      debugPrint('LOCATION ERROR: $error');

      if (!mounted) return;

      setState(() {
        _locationAllowed = false;
      });
    }
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 8,
      ),
    ).listen(
      (position) {
        if (!mounted) return;

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      },
      onError: (Object error) {
        debugPrint('LOCATION STREAM ERROR: $error');
      },
    );
  }

  Future<void> _loadCurrentUser() async {
    try {
      final Map<String, dynamic> profile =
          await AuthService.getProfile(widget.token);

      final Object? data = profile['data'];

      if (!mounted) return;

      if (data is Map) {
        setState(() {
          _currentUserId = _toInt(data['id']);
        });
      }
    } catch (error) {
      debugPrint('LOAD CURRENT USER ERROR: $error');
    }
  }

  Future<void> _loadFoods({bool showRefreshState = false}) async {
    if (showRefreshState && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final List<dynamic> result = await FoodService.getFoods(widget.token);

      if (!mounted) return;

      setState(() {
        _foods = result;
      });
    } catch (error) {
      debugPrint('LOAD FOOD ERROR: $error');

      if (mounted && showRefreshState) {
        _showSnack(
          'Gagal memuat data makanan. Periksa koneksi atau backend.',
          isError: true,
        );
      }
    } finally {
      if (mounted && showRefreshState) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshFoods() async {
    await _loadFoods(showRefreshState: true);
  }

  Future<void> _requestLocationAgain() async {
    await _prepareLocation();

    if (!mounted || !_locationAllowed) return;

    _mapController.move(_currentLocation, 15);
  }

  Future<void> _focusCurrentLocation() async {
    if (!_locationAllowed) {
      await _requestLocationAgain();
      return;
    }

    _mapController.move(_currentLocation, 15);
  }

  Future<void> _showRouteForFood(
    Map<String, dynamic> food,
    int quantity,
  ) async {
    final double? latitude = _toDouble(food['latitude']);
    final double? longitude = _toDouble(food['longitude']);

    if (latitude == null || longitude == null) {
      _showSnack(
        'Lokasi makanan tidak valid.',
        isError: true,
      );
      return;
    }

    final LatLng destination = LatLng(latitude, longitude);

    setState(() {
      _selectedFood = food;
      _selectedDestination = destination;
      _claimQuantity = quantity;
      _routePoints = [];
    });

    try {
      final List<LatLng> points = await RouteService.getRoute(
        currentLocation: _currentLocation,
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _routePoints = points;
      });

      final LatLng center = LatLng(
        (_currentLocation.latitude + latitude) / 2,
        (_currentLocation.longitude + longitude) / 2,
      );

      _mapController.move(center, points.isEmpty ? 14 : 13);

      if (points.isEmpty) {
        _showSnack(
          'Rute belum tersedia. Marker lokasi tetap ditampilkan.',
          isError: false,
        );
      }
    } catch (error) {
      debugPrint('ROUTE ERROR: $error');

      if (!mounted) return;

      _showSnack(
        'Gagal memuat rute. Marker lokasi tetap ditampilkan.',
        isError: true,
      );
    }
  }

  Future<void> _claimSelectedFood() async {
    final Map<String, dynamic>? food = _selectedFood;

    if (food == null) return;

    final int? foodId = _toInt(food['id']);

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isActionBusy = true;
    });

    try {
      final Map<String, dynamic> response = await FoodService.pickFood(
        token: widget.token,
        foodId: foodId,
        quantity: _claimQuantity,
      );

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        throw Exception(
          response['message']?.toString() ?? 'Gagal mengambil makanan.',
        );
      }

      await _loadFoods();

      if (!mounted) return;

      setState(() {
        _selectedFood = {
          ...food,
          'status': 'ON_THE_WAY',
          'claimed_by': _currentUserId,
          'claimed_quantity': _claimQuantity,
        };
      });

      _showSnack(
        'Makanan ditandai sedang diambil.',
        isError: false,
      );
    } catch (error) {
      debugPrint('PICK FOOD ERROR: $error');

      if (!mounted) return;

      _showSnack(
        'Gagal mengambil makanan. Stok mungkin tidak cukup.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionBusy = false;
        });
      }
    }
  }

  Future<void> _confirmPickup() async {
    final Map<String, dynamic>? food = _selectedFood;

    if (food == null) return;

    final int? foodId = _toInt(food['id']);

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isActionBusy = true;
    });

    try {
      await FoodService.confirmPickup(
        token: widget.token,
        foodId: foodId,
      );

      await _loadFoods();

      if (!mounted) return;

      _clearSelection();

      _showSnack(
        'Pengambilan makanan berhasil dikonfirmasi.',
        isError: false,
      );
    } catch (error) {
      debugPrint('CONFIRM PICKUP ERROR: $error');

      if (!mounted) return;

      _showSnack(
        'Gagal mengonfirmasi pengambilan.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionBusy = false;
        });
      }
    }
  }

  Future<void> _cancelPickup() async {
    final Map<String, dynamic>? food = _selectedFood;

    if (food == null) return;

    final int? foodId = _toInt(food['id']);

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isActionBusy = true;
    });

    try {
      await FoodService.cancelPickup(
        token: widget.token,
        foodId: foodId,
      );

      await _loadFoods();

      if (!mounted) return;

      _clearSelection();

      _showSnack(
        'Pengambilan makanan dibatalkan.',
        isError: false,
      );
    } catch (error) {
      debugPrint('CANCEL PICKUP ERROR: $error');

      if (!mounted) return;

      _showSnack(
        'Gagal membatalkan pengambilan.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionBusy = false;
        });
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFood = null;
      _selectedDestination = null;
      _routePoints = [];
      _claimQuantity = 1;
    });
  }

  void _openFoodDetail(Map<String, dynamic> food) {
    final String foodId = _stringValue(food['id'], fallback: 'unknown');
    final String? imageUrl = _resolvePhotoUrl(food['photo_url']);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FoodDetailSheet(
          food: food,
          imageUrl: imageUrl,
          heroTag: 'food-photo-$foodId',
          distanceLabel: _distanceLabel(food),
          expiredAtLabel: _formatExpiredAt(food['expired_at']),
          isOwnedByCurrentUser: _isOwnedByCurrentUser(food),
          isClaimedByCurrentUser: _isClaimedByCurrentUser(food),
          onChatTap: () => _showMockCommunication('Chat room'),
          onAudioCallTap: () => _showMockCommunication('Audio call'),
          onVideoCallTap: () => _showMockCommunication('Video call'),
          onShowRoute: (quantity) {
            _showRouteForFood(food, quantity);
          },
        );
      },
    );
  }

  void _showMockCommunication(String featureName) {
    _showSnack(
      '$featureName akan dihubungkan pada tahap fitur komunikasi in-app.',
      isError: false,
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  List<Map<String, dynamic>> get _visibleFoods {
    final List<Map<String, dynamic>> normalizedFoods = _foods
        .map(_toFoodMap)
        .where((food) => food.isNotEmpty)
        .where((food) => _toDouble(food['latitude']) != null)
        .where((food) => _toDouble(food['longitude']) != null)
        .where((food) => _statusOf(food) != 'PICKED_UP')
        .toList();

    if (_locationAllowed) {
      normalizedFoods.removeWhere(
        (food) => _distanceInMeters(food) > _radiusMeters,
      );
    }

    normalizedFoods.sort(
      (a, b) => _distanceInMeters(a).compareTo(_distanceInMeters(b)),
    );

    return normalizedFoods;
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [
      Marker(
        width: 54,
        height: 54,
        point: _currentLocation,
        child: const _CurrentLocationMarker(),
      ),
    ];

    for (final Map<String, dynamic> food in _visibleFoods) {
      final double? latitude = _toDouble(food['latitude']);
      final double? longitude = _toDouble(food['longitude']);

      if (latitude == null || longitude == null) continue;

      final int? id = _toInt(food['id']);
      final int? selectedId =
          _selectedFood == null ? null : _toInt(_selectedFood!['id']);

      markers.add(
        Marker(
          width: 64,
          height: 64,
          point: LatLng(latitude, longitude),
          child: _FoodMapMarker(
            isSelected: id != null && id == selectedId,
            isOwnedByCurrentUser: _isOwnedByCurrentUser(food),
            statusColor: _statusColor(food),
            onTap: () => _openFoodDetail(food),
          ),
        ),
      );
    }

    if (_selectedDestination != null) {
      markers.add(
        Marker(
          width: 54,
          height: 54,
          point: _selectedDestination!,
          child: const _DestinationMarker(),
        ),
      );
    }

    return markers;
  }

  String _statusOf(Map<String, dynamic> food) {
    return _stringValue(food['status'], fallback: 'POSTED').toUpperCase();
  }

  Color _statusColor(Map<String, dynamic> food) {
    switch (_statusOf(food)) {
      case 'ON_THE_WAY':
        return AppColors.teal;
      case 'PICKED_UP':
        return AppColors.textMuted;
      case 'CANCELED':
        return AppColors.danger;
      case 'POSTED':
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(Map<String, dynamic> food) {
    switch (_statusOf(food)) {
      case 'ON_THE_WAY':
        return 'Sedang diambil';
      case 'PICKED_UP':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      case 'POSTED':
      default:
        return 'Tersedia';
    }
  }

  bool _isOwnedByCurrentUser(Map<String, dynamic> food) {
    final int? ownerId = _toInt(food['user_id']);
    return ownerId != null && ownerId == _currentUserId;
  }

  bool _isClaimedByCurrentUser(Map<String, dynamic> food) {
    final int? claimedBy = _toInt(food['claimed_by']);
    return claimedBy != null && claimedBy == _currentUserId;
  }

  double _distanceInMeters(Map<String, dynamic> food) {
    final double? latitude = _toDouble(food['latitude']);
    final double? longitude = _toDouble(food['longitude']);

    if (latitude == null || longitude == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      latitude,
      longitude,
    );
  }

  String _distanceLabel(Map<String, dynamic> food) {
    final double distance = _distanceInMeters(food);

    if (!distance.isFinite) {
      return '-';
    }

    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }

    return '${distance.round()} m';
  }

  String _formatExpiredAt(Object? rawValue) {
    final String raw = _stringValue(rawValue, fallback: '-');

    if (raw == '-') return raw;

    try {
      final DateTime dateTime = DateTime.parse(raw).toLocal();

      return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year} '
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    } catch (_) {
      return raw;
    }
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String? _resolvePhotoUrl(Object? rawValue) {
    final String raw = rawValue?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return null;
    }

    final Uri? rawUri = Uri.tryParse(raw);

    if (rawUri != null && rawUri.hasScheme) {
      return raw;
    }

    final Uri baseUri = Uri.parse(ApiConfig.baseUrl);
    final String port = baseUri.hasPort ? ':${baseUri.port}' : '';
    final String origin = '${baseUri.scheme}://${baseUri.host}$port';
    final String normalizedPath = raw.startsWith('/') ? raw : '/$raw';

    return '$origin$normalizedPath';
  }

  Map<String, dynamic> _toFoodMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }

    return <String, dynamic>{};
  }

  int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  String _stringValue(Object? value, {required String fallback}) {
    final String raw = value?.toString().trim() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return fallback;
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _HomeSkeletonPage();
    }

    final List<Map<String, dynamic>> visibleFoods = _visibleFoods;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: _locationAllowed ? 14 : 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.food_donation_app',
              ),
              if (_locationAllowed)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation,
                      radius: _radiusMeters,
                      useRadiusInMeter: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderColor: AppColors.primary.withValues(alpha: 0.24),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: AppColors.teal,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2,
                AppSpacing.x2,
                AppSpacing.x2,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(
                    locationAllowed: _locationAllowed,
                    visibleFoodCount: visibleFoods.length,
                    isRefreshing: _isRefreshing,
                    onRefresh: _refreshFoods,
                    onFocusLocation: _focusCurrentLocation,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  _RadiusSelector(
                    radiusMeters: _radiusMeters,
                    onChanged: (value) {
                      setState(() {
                        _radiusMeters = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.x2,
            right: AppSpacing.x2,
            bottom: 72,
            child: _FoodCarousel(
              foods: visibleFoods,
              selectedFoodId:
                  _selectedFood == null ? null : _toInt(_selectedFood!['id']),
              onTap: _openFoodDetail,
              imageUrlOf: (food) => _resolvePhotoUrl(food['photo_url']),
              distanceLabelOf: _distanceLabel,
              statusLabelOf: _statusLabel,
              statusColorOf: _statusColor,
            ),
          ),
          if (_selectedFood != null)
            Positioned(
              left: AppSpacing.x2,
              right: AppSpacing.x2,
              bottom: 72,
              child: _PickupActionBar(
                food: _selectedFood!,
                quantity: _claimQuantity,
                isBusy: _isActionBusy,
                isOwnedByCurrentUser: _isOwnedByCurrentUser(_selectedFood!),
                isClaimedByCurrentUser: _isClaimedByCurrentUser(_selectedFood!),
                statusLabel: _statusLabel(_selectedFood!),
                onClose: _clearSelection,
                onPickNow: _claimSelectedFood,
                onConfirm: _confirmPickup,
                onCancel: _cancelPickup,
              ),
            ),
          if (!_locationAllowed)
            _LocationPermissionOverlay(
              onAllow: _requestLocationAgain,
            ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final bool locationAllowed;
  final int visibleFoodCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onFocusLocation;

  const _HomeHeader({
    required this.locationAllowed,
    required this.visibleFoodCount,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onFocusLocation,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      borderRadius: AppRadius.xl,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donasi Terdekat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationAllowed
                        ? '$visibleFoodCount makanan dalam radius'
                        : 'Izinkan lokasi untuk hasil lebih akurat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh data',
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Lokasi saya',
              onPressed: onFocusLocation,
              icon: const Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  final double radiusMeters;
  final ValueChanged<double> onChanged;

  const _RadiusSelector({
    required this.radiusMeters,
    required this.onChanged,
  });

  static const List<double> _options = [1000, 3000, 5000];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.x1);
        },
        itemBuilder: (context, index) {
          final double value = _options[index];
          final bool isActive = value == radiusMeters;

          return ChoiceChip(
            selected: isActive,
            label: Text('${(value / 1000).toStringAsFixed(0)} km'),
            onSelected: (selected) => onChanged(value),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isActive ? Colors.white : AppColors.primaryDark,
                ),
            side: BorderSide(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          );
        },
      ),
    );
  }
}

class _FoodCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  final int? selectedFoodId;
  final ValueChanged<Map<String, dynamic>> onTap;
  final String? Function(Map<String, dynamic> food) imageUrlOf;
  final String Function(Map<String, dynamic> food) distanceLabelOf;
  final String Function(Map<String, dynamic> food) statusLabelOf;
  final Color Function(Map<String, dynamic> food) statusColorOf;

  const _FoodCarousel({
    required this.foods,
    required this.selectedFoodId,
    required this.onTap,
    required this.imageUrlOf,
    required this.distanceLabelOf,
    required this.statusLabelOf,
    required this.statusColorOf,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return _SurfaceCard(
        borderRadius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  'Belum ada makanan dalam radius ini.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: foods.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.x2);
        },
        itemBuilder: (context, index) {
          final Map<String, dynamic> food = foods[index];
          final String foodId = (food['id'] ?? index).toString();

          return _FoodPreviewCard(
            food: food,
            imageUrl: imageUrlOf(food),
            heroTag: 'food-photo-$foodId',
            distanceLabel: distanceLabelOf(food),
            statusLabel: statusLabelOf(food),
            statusColor: statusColorOf(food),
            isSelected: selectedFoodId?.toString() == foodId,
            onTap: () => onTap(food),
          );
        },
      ),
    );
  }
}

class _FoodPreviewCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final String? imageUrl;
  final String heroTag;
  final String distanceLabel;
  final String statusLabel;
  final Color statusColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FoodPreviewCard({
    required this.food,
    required this.imageUrl,
    required this.heroTag,
    required this.distanceLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = food['food_name']?.toString() ?? 'Makanan';
    final int quantity = _intFromObject(food['quantity']) ?? 0;

    return _SurfaceCard(
      width: 304,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x1),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Hero(
                tag: heroTag,
                child: _FoodImage(
                  imageUrl: imageUrl,
                  width: 92,
                  height: double.infinity,
                  borderRadius: AppRadius.md,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _CompactPill(
                          icon: Icons.location_on_outlined,
                          label: distanceLabel,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        _CompactPill(
                          icon: Icons.inventory_2_outlined,
                          label: '$quantity',
                          color: AppColors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _StatusPill(
                      label: statusLabel,
                      color: statusColor,
                    ),
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

class _FoodDetailSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final String? imageUrl;
  final String heroTag;
  final String distanceLabel;
  final String expiredAtLabel;
  final bool isOwnedByCurrentUser;
  final bool isClaimedByCurrentUser;
  final VoidCallback onChatTap;
  final VoidCallback onAudioCallTap;
  final VoidCallback onVideoCallTap;
  final ValueChanged<int> onShowRoute;

  const _FoodDetailSheet({
    required this.food,
    required this.imageUrl,
    required this.heroTag,
    required this.distanceLabel,
    required this.expiredAtLabel,
    required this.isOwnedByCurrentUser,
    required this.isClaimedByCurrentUser,
    required this.onChatTap,
    required this.onAudioCallTap,
    required this.onVideoCallTap,
    required this.onShowRoute,
  });

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  late int _quantity;

  int get _maxQuantity {
    final int value = _intFromObject(widget.food['quantity']) ?? 1;
    return value < 1 ? 1 : value;
  }

  String get _status {
    return (widget.food['status']?.toString() ?? 'POSTED').toUpperCase();
  }

  bool get _canClaim {
    return _status == 'POSTED' && !widget.isOwnedByCurrentUser;
  }

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;

    setState(() {
      _quantity--;
    });
  }

  void _increaseQuantity() {
    if (_quantity >= _maxQuantity) return;

    setState(() {
      _quantity++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.food['food_name']?.toString() ?? 'Makanan';
    final String description =
        widget.food['description']?.toString() ?? 'Tidak ada deskripsi.';
    final String address =
        widget.food['address']?.toString() ?? 'Alamat belum tersedia.';

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Hero(
                tag: widget.heroTag,
                child: _FoodImage(
                  imageUrl: widget.imageUrl,
                  width: double.infinity,
                  height: 220,
                  borderRadius: AppRadius.xl,
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (widget.isOwnedByCurrentUser)
                    const _StatusPill(
                      label: 'Postingan Anda',
                      color: AppColors.teal,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x3),
              Wrap(
                spacing: AppSpacing.x1,
                runSpacing: AppSpacing.x1,
                children: [
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: widget.distanceLabel,
                  ),
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '$_maxQuantity porsi',
                  ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: widget.expiredAtLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              _InfoPanel(
                icon: Icons.place_outlined,
                title: 'Lokasi Pengambilan',
                description: address,
              ),
              const SizedBox(height: AppSpacing.x2),
              _CommunicationActions(
                onChatTap: widget.onChatTap,
                onAudioCallTap: widget.onAudioCallTap,
                onVideoCallTap: widget.onVideoCallTap,
              ),
              const SizedBox(height: AppSpacing.x3),
              if (widget.isOwnedByCurrentUser)
                const _InfoPanel(
                  icon: Icons.manage_search_rounded,
                  title: 'Postingan milik Anda',
                  description:
                      'Manajemen edit dan hapus postingan akan disiapkan pada tahap CRUD Donatur.',
                )
              else if (!_canClaim)
                _InfoPanel(
                  icon: Icons.info_outline_rounded,
                  title: 'Status makanan',
                  description: widget.isClaimedByCurrentUser
                      ? 'Anda sedang mengambil makanan ini. Gunakan panel aksi di peta untuk konfirmasi atau batal.'
                      : 'Makanan ini sedang diproses oleh pengguna lain.',
                )
              else ...[
                Text(
                  'Jumlah yang ingin diklaim',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.x1),
                _QuantityStepper(
                  quantity: _quantity,
                  maxQuantity: _maxQuantity,
                  onDecrease: _decreaseQuantity,
                  onIncrease: _increaseQuantity,
                ),
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onShowRoute(_quantity);
                    },
                    icon: const Icon(Icons.alt_route_rounded),
                    label: Text('Lihat Rute ($_quantity porsi)'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupActionBar extends StatelessWidget {
  final Map<String, dynamic> food;
  final int quantity;
  final bool isBusy;
  final bool isOwnedByCurrentUser;
  final bool isClaimedByCurrentUser;
  final String statusLabel;
  final VoidCallback onClose;
  final VoidCallback onPickNow;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PickupActionBar({
    required this.food,
    required this.quantity,
    required this.isBusy,
    required this.isOwnedByCurrentUser,
    required this.isClaimedByCurrentUser,
    required this.statusLabel,
    required this.onClose,
    required this.onPickNow,
    required this.onConfirm,
    required this.onCancel,
  });

  String get _status {
    return (food['status']?.toString() ?? 'POSTED').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String name = food['food_name']?.toString() ?? 'Makanan';
    final bool canPick = _status == 'POSTED' && !isOwnedByCurrentUser;
    final bool canManagePickup =
        _status == 'ON_THE_WAY' && isClaimedByCurrentUser;

    return _SurfaceCard(
      borderRadius: AppRadius.xl,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: isBusy ? null : onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$statusLabel • $quantity porsi',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            if (canPick)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onPickNow,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Ambil Sekarang'),
                ),
              )
            else if (canManagePickup)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : onConfirm,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Selesai'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : onCancel,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Batal'),
                      ),
                    ),
                  ),
                ],
              )
            else
              const _InfoPanel(
                icon: Icons.info_outline_rounded,
                title: 'Aksi tidak tersedia',
                description:
                    'Postingan milik sendiri atau makanan sedang diproses pengguna lain.',
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationPermissionOverlay extends StatelessWidget {
  final VoidCallback onAllow;

  const _LocationPermissionOverlay({
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.34),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: _SurfaceCard(
                borderRadius: AppRadius.xl,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primaryDark,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'Aktifkan Lokasi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Lokasi digunakan untuk menghitung radius makanan terdekat dan menampilkan rute pengambilan.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: onAllow,
                          icon: const Icon(Icons.location_searching_rounded),
                          label: const Text('Izinkan Lokasi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.brand,
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.accent,
      ),
      child: const Icon(
        Icons.flag_rounded,
        color: Colors.white,
      ),
    );
  }
}

class _FoodMapMarker extends StatelessWidget {
  final bool isSelected;
  final bool isOwnedByCurrentUser;
  final Color statusColor;
  final VoidCallback onTap;

  const _FoodMapMarker({
    required this.isSelected,
    required this.isOwnedByCurrentUser,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: isSelected ? 62 : 54,
          height: isSelected ? 62 : 54,
          decoration: BoxDecoration(
            color: isOwnedByCurrentUser ? AppColors.teal : statusColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: isSelected ? AppShadows.brand : AppShadows.card,
          ),
          child: Icon(
            isOwnedByCurrentUser
                ? Icons.storefront_rounded
                : Icons.fastfood_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  const _FoodImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.accent,
        size: 34,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: quantity > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'dari $maxQuantity porsi',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: quantity < maxQuantity ? onIncrease : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _CommunicationActions extends StatelessWidget {
  final VoidCallback onChatTap;
  final VoidCallback onAudioCallTap;
  final VoidCallback onVideoCallTap;

  const _CommunicationActions({
    required this.onChatTap,
    required this.onAudioCallTap,
    required this.onVideoCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onChatTap,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Chat'),
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAudioCallTap,
            icon: const Icon(Icons.call_outlined),
            label: const Text('Audio'),
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onVideoCallTap,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Video'),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primaryDark,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double? width;

  const _SurfaceCard({
    required this.child,
    required this.borderRadius,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          child: child,
        ),
      ),
    );
  }
}

class _HomeSkeletonPage extends StatelessWidget {
  const _HomeSkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            children: [
              const _ShimmerBox(
                height: 80,
                borderRadius: AppRadius.xl,
              ),
              const SizedBox(height: AppSpacing.x2),
              const _ShimmerBox(
                height: 44,
                borderRadius: AppRadius.lg,
              ),
              const SizedBox(height: AppSpacing.x2),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Center(
                    child: _ShimmerBox(
                      width: 160,
                      height: 160,
                      borderRadius: AppRadius.xl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              const _ShimmerBox(
                height: 120,
                borderRadius: AppRadius.xl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget base = Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      child: base,
      builder: (context, child) {
        final double offset = _controller.value * 2 - 1;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(offset - 1, 0),
              end: Alignment(offset + 1, 0),
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.58),
                Colors.white.withValues(alpha: 0.12),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}

int? _intFromObject(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}