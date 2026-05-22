import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/food_service.dart';
import '../theme/app_theme.dart';
import 'pick_location_page.dart';

class AddFoodPage extends StatefulWidget {
  final String token;

  const AddFoodPage({
    super.key,
    required this.token,
  });

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _imagePreviewBytes;
  ImageOptimizationResult? _optimizationResult;

  int _quantity = 1;
  bool _isPickingImage = false;
  bool _isOptimizingImage = false;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  double _latitude = -6.9733;
  double _longitude = 107.6300;

  DateTime _expiredAt = DateTime.now().add(const Duration(hours: 3));

  String get _expiredAtDisplay {
    return '${_twoDigits(_expiredAt.day)}/${_twoDigits(_expiredAt.month)}/${_expiredAt.year} '
        '${_twoDigits(_expiredAt.hour)}:${_twoDigits(_expiredAt.minute)}';
  }

  String get _coordinateDisplay {
    return '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';
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
    if (!mounted) return;

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
      if (!mounted) return;

      _showSnack(
        'Gagal memilih gambar: $error',
        isError: true,
      );
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

    final DateTime firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime lastDate = DateTime(
      maxTime.year,
      maxTime.month,
      maxTime.day,
    );

    final DateTime initialDate = _expiredAt.isAfter(maxTime)
        ? lastDate
        : DateTime(_expiredAt.year, _expiredAt.month, _expiredAt.day);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation || _isSubmitting) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          _isGettingLocation = false;
        });

        _showSnack(
          'Location service belum aktif.',
          isError: true,
        );

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
          _isGettingLocation = false;
        });

        _showSnack(
          'Izin lokasi belum diberikan.',
          isError: true,
        );

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

    if (_selectedImage == null) {
      _showSnack(
        'Pilih foto makanan terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showSnack(
        'Lokasi pickup belum dipilih.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ImageOptimizationResult optimization =
          _optimizationResult ??
              await FoodService.optimizeImageForUpload(_selectedImage!);

      final Map<String, dynamic> response = await FoodService.createFood(
        token: widget.token,
        foodName: _foodNameController.text,
        description: _descriptionController.text,
        quantity: _quantity,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text,
        expiredAt: _expiredAt.toIso8601String(),
        image: _selectedImage!,
        optimizedImage: optimization,
      );

      if (!mounted) return;

      final bool isSuccess = response['success'] != false;

      if (!isSuccess) {
        _showSnack(
          FoodService.messageOf(
            response,
            fallback: 'Gagal memposting makanan.',
          ),
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      await _showSuccessDialog(optimization);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showSnack(
        'Gagal membuat postingan: $error',
        isError: true,
      );
    }
  }

  Future<void> _showSuccessDialog(
    ImageOptimizationResult optimization,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          contentPadding: const EdgeInsets.all(AppSpacing.x3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Donasi Berhasil Diposting',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                'Estimasi payload gambar: ${optimization.estimatedUploadSizeLabel}. '
                'Data ini bisa dipakai sebagai bahan analisis bandwidth.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        );
      },
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

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Donasi'),
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
                        const _GuidanceCard(),
                        const SizedBox(height: AppSpacing.x3),
                        _SectionCard(
                          title: 'Foto Makanan',
                          subtitle:
                              'Foto akan dianalisis untuk simulasi optimasi payload upload.',
                          child: _ImagePickerBox(
                            imageBytes: _imagePreviewBytes,
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
                              'Informasi ini membantu konsumen menilai kelayakan makanan.',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _foodNameController,
                                enabled: !_isSubmitting,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nama makanan',
                                  hintText: 'Contoh: Nasi Box Ayam',
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
                                  hintText:
                                      'Jelaskan kondisi, isi paket, dan catatan pengambilan',
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
                          title: 'Jumlah dan Batas Waktu',
                          subtitle:
                              'Batas waktu maksimal 6 jam untuk menjaga keamanan konsumsi.',
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
                              'Pilih titik lokasi agar konsumen bisa melihat radius dan rute.',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _addressController,
                                readOnly: true,
                                enabled: !_isSubmitting,
                                onTap: _openPickLocationPage,
                                decoration: const InputDecoration(
                                  labelText: 'Koordinat / alamat pickup',
                                  hintText: 'Pilih lokasi pickup',
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
                                : const Icon(Icons.publish_rounded),
                            label: Text(
                              _isSubmitting
                                  ? 'Memposting...'
                                  : 'Posting Donasi',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
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

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

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
                Icons.volunteer_activism_rounded,
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
                    'Mode Donatur',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Satu akun User dapat membuat postingan makanan sekaligus mengklaim makanan.',
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
  final bool isPicking;
  final bool isOptimizing;
  final VoidCallback onTap;

  const _ImagePickerBox({
    required this.imageBytes,
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
          border: Border.all(
            color: AppColors.border,
          ),
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
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.accent,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Tambah Foto Makanan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galeri atau kamera',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              if (imageBytes != null)
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
                            'Ganti',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulasi Image Optimizer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Untuk analisis bandwidth upload.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Original',
                    value: result.originalSizeLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _MetricTile(
                    label: 'Estimasi Upload',
                    value: result.estimatedUploadSizeLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _MetricTile(
                    label: 'Hemat',
                    value:
                        '${result.estimatedSavedPercent.toStringAsFixed(1)}%',
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
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
                'Pilih Sumber Foto',
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