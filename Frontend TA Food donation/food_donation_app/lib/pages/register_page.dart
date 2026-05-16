import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'verify_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

  // Getters untuk validasi password
  bool get _hasMinLength => passwordController.text.length >= 8;
  bool get _hasUpperCase => passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _passwordValid => _hasMinLength && _hasUpperCase && _hasDigit;
  bool get _passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  String? get _passwordErrorText {
    if (!_passwordTouched) return null;
    if (passwordController.text.isEmpty) return 'Password tidak boleh kosong';
    List<String> errors = [];
    if (!_hasMinLength) errors.add('minimal 8 karakter');
    if (!_hasUpperCase) errors.add('minimal 1 huruf kapital');
    if (!_hasDigit) errors.add('minimal 1 angka');
    if (errors.isEmpty) return null;
    return 'Password harus mengandung: ${errors.join(', ')}';
  }

  String? get _confirmPasswordErrorText {
    if (!_confirmPasswordTouched) return null;
    if (confirmPasswordController.text.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (!_passwordsMatch) return 'Password tidak sama';
    return null;
  }

  Future<void> register() async {
    setState(() {
      _passwordTouched = true;
      _confirmPasswordTouched = true;
    });

    if (!_passwordValid) return;
    if (!_passwordsMatch) return;

    try {
      setState(() => isLoading = true);

      final response = await AuthService.register(
        fullName: fullNameController.text,
        phone: phoneController.text,
        email: emailController.text,
        password: passwordController.text,
      );

      setState(() => isLoading = false);

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP telah dikirim ke email'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPage(
              verificationToken: response['data']['verification_token']
                  .toString(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Register failed')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot connect to backend: $e')));
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Center(
                child: Text(
                  'LOGO',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 40),

              // Tab Login / Sign Up
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xffB8E3C8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(child: Text('Login')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xff0C6B3C),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Full Name
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Phone Number — hanya angka
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                onChanged: (_) {
                  setState(() {
                    _passwordTouched = true;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              // Peringatan password
              if (_passwordErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    _passwordErrorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                onChanged: (_) {
                  setState(() {
                    _confirmPasswordTouched = true;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              // Peringatan confirm password
              if (_confirmPasswordErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    _confirmPasswordErrorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 40),

              // Tombol Sign Up
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff8FD5A9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white, fontSize: 18),
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
