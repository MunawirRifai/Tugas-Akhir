import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/food_service.dart';
import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';
import 'pick_location_page.dart';

class EditFoodPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> food;

  const EditFoodPage({
    super.key,
    required this.token,
    required this.food,
  });

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late final FoodRecord _initialFood;

  XFile? _selectedImage;
  Uint8List? _imagePreviewBytes;
  ImageOptimizationResult? _optimizationResult;

  int _quantity = 1;
  double _latitude = -6.9733;
  double _longitude = 107.6300;
  DateTime _expiredAt = DateTime.now().add(const Duration(hours: 3));

  bool _isPickingImage = false;
  bool _isOptimizingImage = false;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  String get _expiredAtDisplay {
    return '${_twoDigits(_expiredAt.day)}/${_twoDigits(_expiredAt.month)}/${_expiredAt.year} '
        '${_twoDigits(_expiredAt.hour)}:${_twoDigits(_expiredAt.minute)}';
  }

  String get _coordinateDisplay {
    return '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';
  }

  String? get _existingImageUrl {
    if (_selectedImage != null) return null;
    return _initialFood.photoUrl;
  }

  @override
  void initState() {
    super.initState();

    _initialFood = FoodRecord(widget.food);

    _foodNameController.text = _initialFood.name;
    _descriptionController.text =
        _initialFood.description == 'Tidak ada deskripsi.'
            ? ''
            : _initialFood.description;
    _addressController.text =
        _initialFood.address == 'Lokasi belum tersedia.'
            ? _initialFood.coordinateLabel
            : _initialFood.address;

    _quantity = _initialFood.quantity < 1 ? 1 : _initialFood.quantity;
    _latitude = _initialFood.latitude ?? _latitude;
    _longitude = _initialFood.longitude ?? _longitude;

    final DateTime now = DateTime.now();
    final DateTime fallbackExpiredAt = now.add(const Duration(hours: 3));
    final DateTime? currentExpiredAt = _initialFood.expiredAt;

    if (currentExpiredAt == null || currentExpiredAt.isBefore(now)) {
      _expiredAt = fallbackExpiredAt;
    } else {
      _expiredAt = currentExpiredAt;
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isSubmitting) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ImageSourceSheet(
          onGalleryTap: () => Navigator.of(context).pop(ImageSource.gallery),
          onCameraTap: () => Navigator.of(context).pop(ImageSource.camera),
        );
      },
    );

    if (source == null) return;

    setState(() {
      _isPickingImage = true;
      _isOptimizingImage = false;
    });

    XFile? image;

    try {
      image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );
    } catch (error) {
      if (mounted) {
        _showSnack(
          'Gagal memilih gambar: $error',
          isError: true,
        );
      }
    }

    if (!mounted) return;

    if (image == null) {
      setState(() {
        _isPickingImage = false;
        _isOptimizingImage = false;
      });
      return;
    }

    try {
      final Uint8List previewBytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _imagePreviewBytes = previewBytes;
        _optimizationResult = null;
        _isPickingImage = false;
        _isOptimizingImage = true;
      });

      final ImageOptimizationResult optimization =
          await FoodService.optimizeImageForUpload(image);

      if (!mounted) return;

      setState(() {
        _optimizationResult = optimization;
        _isOptimizingImage = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPickingImage = false;
        _isOptimizingImage = false;
      });

      _showSnack(
        'Gagal membaca gambar: $error',
        isError: true,
      );
    }
  }

  Future<void> _pickExpiredAt() async {
    if (_isSubmitting) return;

    final DateTime now = DateTime.now();
    final DateTime maxTime = now.add(const Duration(hours: 6));
    final DateTime initialDate = _safeInitialDate(now, maxTime);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(maxTime.year, maxTime.month, maxTime.day),
      helpText: 'Pilih Tanggal Batas Pengambilan',
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiredAt),
      helpText: 'Pilih Waktu Batas Pengambilan',
    );

    if (pickedTime == null) return;

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combined.isBefore(now)) {
      _showSnack(
        'Batas waktu tidak boleh di masa lalu.',
        isError: true,
      );
      return;
    }

    if (combined.isAfter(maxTime)) {
      _showSnack(
        'Batas waktu maksimal 6 jam dari sekarang.',
        isError: true,
      );
      return;
    }

    setState(() {
      _expiredAt = combined;
    });
  }

  DateTime _safeInitialDate(DateTime now, DateTime maxTime) {
    if (_expiredAt.isBefore(now)) {
      return now;
    }

    if (_expiredAt.isAfter(maxTime)) {
      return maxTime;
    }

    return _expiredAt;
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation || _isSubmitting) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack(
          'Location service belum aktif.',
          isError: true,
        );

        if (mounted) {
          setState(() {
            _isGettingLocation = false;
          });
        }

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack(
          'Izin lokasi belum diberikan.',
          isError: true,
        );

        if (mounted) {
          setState(() {
            _isGettingLocation = false;
          });
        }

        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = _coordinateDisplay;
        _isGettingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });

      _showSnack(
        'Gagal membaca lokasi: $error',
        isError: true,
      );
    }
  }

  Future<void> _openPickLocationPage() async {
    if (_isSubmitting) return;

    final LatLng? selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PickLocationPage(
          initialLocation: LatLng(_latitude, _longitude),
        ),
      ),
    );

    if (selectedLocation == null || !mounted) return;

    setState(() {
      _latitude = selectedLocation.latitude;
      _longitude = selectedLocation.longitude;
      _addressController.text = _coordinateDisplay;
    });
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final int? foodId = _initialFood.id;

    if (foodId == null) {
      _showSnack(
        'ID makanan tidak valid.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      ImageOptimizationResult? optimization;

      if (_selectedImage != null) {
        optimization = _optimizationResult ??
            await FoodService.optimizeImageForUpload(_selectedImage!);
      }

      final Map<String, dynamic> response = await FoodService.updateFood(
        token: widget.token,
        foodId: foodId,
        foodName: _foodNameController.text,
        description: _descriptionController.text,
        quantity: _quantity,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text,
        expiredAt: _expiredAt.toIso8601String(),
        image: _selectedImage,
        optimizedImage: optimization,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        _showSnack(
          FoodService.messageOf(
            response,
            fallback: 'Gagal memperbarui postingan.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      _showSnack(
        'Postingan berhasil diperbarui.',
        isError: false,
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memperbarui postingan: $error',
        isError: true,
      );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Donasi'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EditHeader(
                          statusLabel: _initialFood.statusLabel,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        _SectionCard(
                          title: 'Foto Makanan',
                          subtitle:
                              'Pilih foto baru jika ingin mengganti gambar lama.',
                          child: _ImagePickerBox(
                            imageBytes: _imagePreviewBytes,
                            existingImageUrl: _existingImageUrl,
                            isPicking: _isPickingImage,
                            isOptimizing: _isOptimizingImage,
                            onTap: _pickImage,
                          ),
                        ),
                        if (_optimizationResult != null) ...[
                          const SizedBox(height: AppSpacing.x2),
                          _ImageOptimizationCard(
                            result: _optimizationResult!,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.x2),
                        _SectionCard(
                          title: 'Detail Donasi',
                          subtitle:
                              'Perbarui nama dan deskripsi makanan.',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _foodNameController,
                                enabled: !_isSubmitting,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nama makanan',
                                  prefixIcon:
                                      Icon(Icons.restaurant_menu_rounded),
                                ),
                                validator: (value) {
                                  final String foodName =
                                      value?.trim() ?? '';

                                  if (foodName.isEmpty) {
                                    return 'Nama makanan tidak boleh kosong';
                                  }

                                  if (foodName.length < 3) {
                                    return 'Nama makanan minimal 3 karakter';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: !_isSubmitting,
                                maxLines: 4,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Deskripsi',
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(Icons.notes_rounded),
                                ),
                                validator: (value) {
                                  final String description =
                                      value?.trim() ?? '';

                                  if (description.isEmpty) {
                                    return 'Deskripsi tidak boleh kosong';
                                  }

                                  if (description.length < 10) {
                                    return 'Deskripsi minimal 10 karakter';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        _SectionCard(
                          title: 'Jumlah dan Waktu',
                          subtitle:
                              'Sesuaikan stok dan batas waktu pengambilan.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _QuantityStepper(
                                quantity: _quantity,
                                onDecrease: _quantity > 1
                                    ? () {
                                        setState(() {
                                          _quantity--;
                                        });
                                      }
                                    : null,
                                onIncrease: () {
                                  setState(() {
                                    _quantity++;
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              _DatePickerTile(
                                expiredAtDisplay: _expiredAtDisplay,
                                onTap: _pickExpiredAt,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        _SectionCard(
                          title: 'Lokasi Pickup',
                          subtitle:
                              'Perbarui titik lokasi jika tempat pickup berubah.',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _addressController,
                                readOnly: true,
                                enabled: !_isSubmitting,
                                onTap: _openPickLocationPage,
                                decoration: const InputDecoration(
                                  labelText: 'Koordinat / alamat pickup',
                                  prefixIcon:
                                      Icon(Icons.location_on_outlined),
                                  suffixIcon: Icon(Icons.map_rounded),
                                ),
                                validator: (value) {
                                  final String address =
                                      value?.trim() ?? '';

                                  if (address.isEmpty) {
                                    return 'Lokasi pickup belum dipilih';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isGettingLocation ||
                                              _isSubmitting
                                          ? null
                                          : _useCurrentLocation,
                                      icon: _isGettingLocation
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                            ),
                                      label: const Text('Lokasi Saya'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.x1),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _openPickLocationPage,
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text('Buka Peta'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _isSubmitting
                                  ? 'Menyimpan...'
                                  : 'Simpan Perubahan',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  final String statusLabel;

  const _EditHeader({
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brand,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Postingan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status saat ini: $statusLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            child,
          ],
        ),
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final bool isPicking;
  final bool isOptimizing;
  final VoidCallback onTap;

  const _ImagePickerBox({
    required this.imageBytes,
    required this.existingImageUrl,
    required this.isPicking,
    required this.isOptimizing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isPicking || isOptimizing;

    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 208,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageBytes != null)
                Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                )
              else if (existingImageUrl != null)
                Image.network(
                  existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _ImagePlaceholder();
                  },
                )
              else
                const _ImagePlaceholder(),
              Positioned(
                right: AppSpacing.x1,
                bottom: AppSpacing.x1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.x2,
                      vertical: AppSpacing.x1,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ganti Foto',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isBusy)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.38),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.accentSoft,
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.accent,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _ImageOptimizationCard extends StatelessWidget {
  final ImageOptimizationResult result;

  const _ImageOptimizationCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
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
                Icons.network_check_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                'Estimasi upload ${result.estimatedUploadSizeLabel}, hemat ${result.estimatedSavedPercent.toStringAsFixed(1)}%.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
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
            onPressed: onDecrease,
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
                  'porsi tersedia',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String expiredAtDisplay;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.expiredAtDisplay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x2),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batas Pengambilan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiredAtDisplay,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;

  const _ImageSourceSheet({
    required this.onGalleryTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                'Pilih Foto Baru',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGalleryTap,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCameraTap,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
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