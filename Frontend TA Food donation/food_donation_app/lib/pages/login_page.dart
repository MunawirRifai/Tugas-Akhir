import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth/auth_scaffold.dart';
import 'main_navigation_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final response = await AuthService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response['success'] != true) {
      _showSnack(
        AuthService.messageOf(
          response,
          fallback: 'Login gagal. Periksa email dan password.',
        ),
        isError: true,
      );
      return;
    }

    final accessToken = AuthService.extractAccessToken(response);

    if (accessToken == null) {
      _showSnack(
        'Login berhasil, tetapi access token tidak ditemukan pada respons backend.',
        isError: true,
      );
      return;
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString('access_token', accessToken);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigationPage(token: accessToken),
      ),
      (route) => false,
    );
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk ke Akun',
      subtitle:
          'Gunakan akun yang sama untuk membuat donasi makanan dan mengklaim makanan.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Belum punya akun?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: _isLoading ? null : _goToRegister,
            child: const Text('Daftar'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthModeSwitch(
              activeMode: AuthMode.login,
              onRegisterTap: _isLoading ? null : _goToRegister,
            ),
            const SizedBox(height: AppSpacing.x3),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email tidak boleh kosong';
                }

                if (!_emailRegex.hasMatch(email)) {
                  return 'Format email tidak valid';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final password = value ?? '';

                if (password.isEmpty) {
                  return 'Password tidak boleh kosong';
                }

                if (password.length < 8) {
                  return 'Password minimal 8 karakter';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!_isLoading) {
                  _login();
                }
              },
            ),
            const SizedBox(height: AppSpacing.x1),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _showSnack(
                          'Fitur reset password belum tersedia di backend.',
                          isError: false,
                        );
                      },
                child: const Text('Lupa password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            AuthPrimaryButton(
              label: 'Masuk',
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              onPressed: _login,
            ),
            const SizedBox(height: AppSpacing.x2),
            const AuthInfoBox(
              icon: Icons.verified_user_outlined,
              text:
                  'Sistem memakai satu akun User. Setelah login, user dapat menjadi donatur maupun konsumen.',
            ),
          ],
        ),
      ),
    );
  }
}