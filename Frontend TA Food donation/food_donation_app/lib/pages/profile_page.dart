import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({
    super.key, required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  late String token;
  String? role;

  String? photoUrl;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final response = await AuthService.getProfile(token);
      final data = response['data'] ?? {};

      setState(() {
        fullNameController.text = data['full_name']?.toString() ?? '';
        phoneController.text = data['phone']?.toString() ?? '';
        emailController.text = data['email']?.toString() ?? '';
        role = data['role']?.toString();
        final photo = data['photo_url']?.toString();
        photoUrl = (photo != null && photo.isNotEmpty) ? photo : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final response = await AuthService.uploadProfilePhoto(
        token: token,
        image: image,
      );

      setState(() {
        final photo = response['data']?['photo_url']?.toString();
        photoUrl = (photo != null && photo.isNotEmpty) ? photo : null;
      });
    } catch (e) {
      debugPrint('UPLOAD PHOTO ERROR: $e');
    }
  }

  Future<void> saveProfile() async {
    try {
      final response = await AuthService.updateProfile(
        token: token,
        fullName: fullNameController.text,
        email: emailController.text,
        phone: phoneController.text,
      );

      if (response['data'] != null &&
          response['data']['access_token'] != null) {
        token = response['data']['access_token'];
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile berhasil diupdate')),
      );
      await loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE6DDF7),
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF98D8B0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                    if (role == 'ROLE_ADMIN') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminDashboardPage(token: widget.token),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Buka Dashboard Admin'),
                        ),
                      ),
                    ]
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