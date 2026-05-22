import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({
    super.key,
    required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isLoggingOut = false;

  String? _photoUrl;
  Uint8List? _localAvatarPreviewBytes;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> response =
          await AuthService.getProfile(widget.token);

      final Map<String, dynamic> profile = _extractProfileMap(response);

      if (!mounted) return;

      setState(() {
        _fullNameController.text = FoodMapper.textOf(
          FoodMapper.valueOf(
            profile,
            ['fullName', 'full_name', 'name', 'username'],
          ),
          fallback: 'User FoodShare',
        );

        _emailController.text = FoodMapper.textOf(
          FoodMapper.valueOf(profile, ['email']),
          fallback: '',
        );

        _phoneController.text = FoodMapper.textOf(
          FoodMapper.valueOf(
            profile,
            ['phone', 'phone_number', 'mobile', 'contact'],
          ),
          fallback: '',
        );

        _photoUrl = FoodMapper.resolvePhotoUrl(
          FoodMapper.valueOf(
            profile,
            [
              'photo_url',
              'photoUrl',
              'profile_photo',
              'profilePhoto',
              'avatar',
              'image',
            ],
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memuat profil: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> _extractProfileMap(Map<String, dynamic> response) {
    final Map<String, dynamic> dataMap = FoodMapper.mapOf(response['data']);

    if (dataMap.isNotEmpty) {
      final Map<String, dynamic> nestedUser = FoodMapper.mapOf(dataMap['user']);

      if (nestedUser.isNotEmpty) {
        return nestedUser;
      }

      final Map<String, dynamic> nestedProfile =
          FoodMapper.mapOf(dataMap['profile']);

      if (nestedProfile.isNotEmpty) {
        return nestedProfile;
      }

      return dataMap;
    }

    final Map<String, dynamic> responseUser = FoodMapper.mapOf(
      response['user'],
    );

    if (responseUser.isNotEmpty) {
      return responseUser;
    }

    return response;
  }

  Future<void> _saveProfile() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> response = await AuthService.updateProfile(
        token: widget.token,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Gagal memperbarui profil.',
          ),
          isError: true,
        );

        setState(() {
          _isSaving = false;
        });

        return;
      }

      _showSnack(
        'Profil berhasil diperbarui.',
        isError: false,
      );

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memperbarui profil: $error',
        isError: true,
      );

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto || _isSaving) return;

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
      _isUploadingPhoto = true;
    });

    XFile? image;

    try {
      image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal memilih foto: $error',
        isError: true,
      );
    }

    if (!mounted) return;

    if (image == null) {
      setState(() {
        _isUploadingPhoto = false;
      });
      return;
    }

    try {
      final Uint8List previewBytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _localAvatarPreviewBytes = previewBytes;
      });

      final Map<String, dynamic> response =
          await AuthService.uploadProfilePhoto(
        token: widget.token,
        image: image,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        _showSnack(
          AuthService.messageOf(
            response,
            fallback: 'Gagal mengunggah foto profil.',
          ),
          isError: true,
        );

        setState(() {
          _isUploadingPhoto = false;
        });

        return;
      }

      final String? uploadedPhotoUrl = _extractPhotoUrl(response);

      setState(() {
        _photoUrl = uploadedPhotoUrl ?? _photoUrl;
        _isUploadingPhoto = false;
      });

      _showSnack(
        'Foto profil berhasil diperbarui.',
        isError: false,
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        'Gagal mengunggah foto profil: $error',
        isError: true,
      );

      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  String? _extractPhotoUrl(Map<String, dynamic> response) {
    final Map<String, dynamic> profile = _extractProfileMap(response);

    return FoodMapper.resolvePhotoUrl(
      FoodMapper.valueOf(
        profile,
        [
          'photo_url',
          'photoUrl',
          'profile_photo',
          'profilePhoto',
          'avatar',
          'image',
        ],
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: const Text('Keluar dari Akun?'),
          content: const Text(
            'Anda perlu login kembali untuk mengakses fitur donasi dan klaim makanan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.remove('access_token');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _ProfileSkeletonPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            96,
          ),
          children: [
            _ProfileHeader(
              fullName: _fullNameController.text,
              email: _emailController.text,
              photoUrl: _photoUrl,
              localAvatarPreviewBytes: _localAvatarPreviewBytes,
              isUploadingPhoto: _isUploadingPhoto,
              onChangePhoto: _pickAndUploadPhoto,
            ),
            const SizedBox(height: AppSpacing.x3),
            _RoleSummaryCard(
              onRefresh: _loadProfile,
            ),
            const SizedBox(height: AppSpacing.x3),
            _AccountFormCard(
              formKey: _formKey,
              fullNameController: _fullNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              emailRegex: _emailRegex,
              isEditing: _isEditing,
              isSaving: _isSaving,
              onToggleEdit: _toggleEditMode,
              onSave: _saveProfile,
            ),
            const SizedBox(height: AppSpacing.x3),
            _NetworkIdentityCard(
              token: widget.token,
            ),
            const SizedBox(height: AppSpacing.x3),
            _DangerZoneCard(
              isLoggingOut: _isLoggingOut,
              onLogout: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String? photoUrl;
  final Uint8List? localAvatarPreviewBytes;
  final bool isUploadingPhoto;
  final VoidCallback onChangePhoto;

  const _ProfileHeader({
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.localAvatarPreviewBytes,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
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
        child: Column(
          children: [
            _ProfileAvatar(
              photoUrl: photoUrl,
              localAvatarPreviewBytes: localAvatarPreviewBytes,
              isUploadingPhoto: isUploadingPhoto,
              onTap: onChangePhoto,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              fullName.trim().isEmpty ? 'User FoodShare' : fullName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              email.trim().isEmpty ? 'Email belum tersedia' : email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final Uint8List? localAvatarPreviewBytes;
  final bool isUploadingPhoto;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.localAvatarPreviewBytes,
    required this.isUploadingPhoto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 58,
      ),
    );

    Widget avatar = fallback;

    if (localAvatarPreviewBytes != null) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Image.memory(
          localAvatarPreviewBytes!,
          width: 104,
          height: 104,
          fit: BoxFit.cover,
        ),
      );
    } else if (photoUrl != null) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Image.network(
          photoUrl!,
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -6,
          bottom: -6,
          child: InkWell(
            onTap: isUploadingPhoto ? null : onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: AppShadows.accent,
              ),
              child: isUploadingPhoto
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleSummaryCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _RoleSummaryCard({
    required this.onRefresh,
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.switch_account_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Single User Entity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Satu akun dapat berperan sebagai Donatur dan Konsumen.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh profil',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: _RoleTile(
                    icon: Icons.storefront_rounded,
                    label: 'Donatur',
                    description: 'Posting makanan',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _RoleTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Konsumen',
                    description: 'Klaim makanan',
                    color: AppColors.teal,
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

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _RoleTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _AccountFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final RegExp emailRegex;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onToggleEdit;
  final VoidCallback onSave;

  const _AccountFormCard({
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.emailRegex,
    required this.isEditing,
    required this.isSaving,
    required this.onToggleEdit,
    required this.onSave,
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
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Informasi Akun',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: isSaving ? null : onToggleEdit,
                    icon: Icon(
                      isEditing
                          ? Icons.close_rounded
                          : Icons.edit_outlined,
                    ),
                    label: Text(isEditing ? 'Batal' : 'Edit'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: fullNameController,
                enabled: isEditing && !isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final String fullName = value?.trim() ?? '';

                  if (fullName.isEmpty) {
                    return 'Nama lengkap tidak boleh kosong';
                  }

                  if (fullName.length < 3) {
                    return 'Nama minimal 3 karakter';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: emailController,
                enabled: isEditing && !isSaving,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final String email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }

                  if (!emailRegex.hasMatch(email)) {
                    return 'Format email tidak valid';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: phoneController,
                enabled: isEditing && !isSaving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nomor kontak akun',
                  helperText: 'Tidak dipakai untuk in-app call/VoIP.',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
                validator: (value) {
                  final String phone = value?.trim() ?? '';

                  if (phone.isEmpty) {
                    return 'Nomor kontak tidak boleh kosong';
                  }

                  if (phone.length < 8) {
                    return 'Nomor kontak minimal 8 karakter';
                  }

                  return null;
                },
              ),
              if (isEditing) ...[
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
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
                      isSaving ? 'Menyimpan...' : 'Simpan Profil',
                    ),
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

class _NetworkIdentityCard extends StatelessWidget {
  final String token;

  const _NetworkIdentityCard({
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final String tokenPreview = token.length <= 14
        ? token
        : '${token.substring(0, 7)}...${token.substring(token.length - 7)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identitas Sesi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Token: $tokenPreview',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Digunakan untuk autentikasi request API, analisis keamanan, dan flow user tunggal.',
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

class _DangerZoneCard extends StatelessWidget {
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const _DangerZoneCard({
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.22),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Akun',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Keluar dari sesi aplikasi saat ini.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isLoggingOut ? null : onLogout,
                icon: isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(isLoggingOut ? 'Logout...' : 'Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
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
                'Pilih Foto Profil',
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

class _ProfileSkeletonPage extends StatelessWidget {
  const _ProfileSkeletonPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              const _SkeletonBox(height: 236),
              const SizedBox(height: AppSpacing.x2),
              const _SkeletonBox(height: 172),
              const SizedBox(height: AppSpacing.x2),
              const _SkeletonBox(height: 280),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}