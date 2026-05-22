import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth/auth_scaffold.dart';
import 'login_page.dart';
import 'verify_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _passwordController.text.contains(RegExp(r'[0-9]'));

  bool get _isPasswordValid => _hasMinLength && _hasUppercase && _hasDigit;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final response = await AuthService.register(
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response['success'] != true) {
      _showSnack(
        AuthService.messageOf(
          response,
          fallback: 'Registrasi gagal. Periksa kembali data Anda.',
        ),
        isError: true,
      );
      return;
    }

    final verificationToken = AuthService.extractVerificationToken(response);

    if (verificationToken == null) {
      _showSnack(
        'Registrasi berhasil, tetapi verification token tidak ditemukan pada respons backend.',
        isError: true,
      );
      return;
    }

    _showSnack(
      'Kode OTP telah dikirim ke email.',
      isError: false,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyPage(
          verificationToken: verificationToken,
          email: _emailController.text.trim().toLowerCase(),
        ),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
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
      title: 'Buat Akun',
      subtitle:
          'Satu akun dapat digunakan untuk membagikan makanan dan mengklaim makanan terdekat.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sudah punya akun?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: _isLoading ? null : _goToLogin,
            child: const Text('Login'),
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
              activeMode: AuthMode.register,
              onLoginTap: _isLoading ? null : _goToLogin,
            ),
            const SizedBox(height: AppSpacing.x3),
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                hintText: 'Masukkan nama lengkap',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                final fullName = value?.trim() ?? '';

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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(
                labelText: 'Nomor kontak akun',
                hintText: 'Contoh: 081234567890',
                helperText: 'Tidak digunakan untuk fitur panggilan in-app.',
                prefixIcon: Icon(Icons.phone_iphone_rounded),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';

                if (phone.isEmpty) {
                  return 'Nomor kontak tidak boleh kosong';
                }

                if (phone.length < 8) {
                  return 'Nomor kontak minimal 8 digit';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x2),
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
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Minimal 8 karakter',
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
              onChanged: (_) {
                setState(() {});
              },
              validator: (value) {
                final password = value ?? '';

                if (password.isEmpty) {
                  return 'Password tidak boleh kosong';
                }

                if (!_isPasswordValid) {
                  return 'Password belum memenuhi kriteria';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x1),
            _PasswordRules(
              hasMinLength: _hasMinLength,
              hasUppercase: _hasUppercase,
              hasDigit: _hasDigit,
            ),
            const SizedBox(height: AppSpacing.x2),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Konfirmasi password',
                hintText: 'Ulangi password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final confirmPassword = value ?? '';

                if (confirmPassword.isEmpty) {
                  return 'Konfirmasi password tidak boleh kosong';
                }

                if (confirmPassword != _passwordController.text) {
                  return 'Password tidak sama';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!_isLoading) {
                  _register();
                }
              },
            ),
            const SizedBox(height: AppSpacing.x3),
            AuthPrimaryButton(
              label: 'Daftar',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _isLoading,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRules extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasDigit;

  const _PasswordRules({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasDigit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PasswordRuleItem(
            label: 'Minimal 8 karakter',
            isValid: hasMinLength,
          ),
          const SizedBox(height: 6),
          _PasswordRuleItem(
            label: 'Minimal 1 huruf kapital',
            isValid: hasUppercase,
          ),
          const SizedBox(height: 6),
          _PasswordRuleItem(
            label: 'Minimal 1 angka',
            isValid: hasDigit,
          ),
        ],
      ),
    );
  }
}

class _PasswordRuleItem extends StatelessWidget {
  final String label;
  final bool isValid;

  const _PasswordRuleItem({
    required this.label,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: isValid ? AppColors.primary : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isValid
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}