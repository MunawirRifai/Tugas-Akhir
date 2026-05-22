import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth/auth_scaffold.dart';
import 'login_page.dart';

class VerifyPage extends StatefulWidget {
  final String verificationToken;
  final String? email;

  const VerifyPage({
    super.key,
    required this.verificationToken,
    this.email,
  });

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final response = await AuthService.verifyRegister(
      verificationToken: widget.verificationToken,
      code: _codeController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response['success'] != true) {
      _showSnack(
        AuthService.messageOf(
          response,
          fallback: 'Verifikasi gagal. Periksa kembali kode OTP.',
        ),
        isError: true,
      );
      return;
    }

    _showSnack(
      'Verifikasi berhasil. Silakan login.',
      isError: false,
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String targetEmail = widget.email?.trim().isNotEmpty == true
        ? widget.email!.trim()
        : 'email Anda';

    return AuthScaffold(
      leading: IconButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: 'Verifikasi Email',
      subtitle: 'Masukkan kode OTP yang dikirim ke $targetEmail.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthInfoBox(
              icon: Icons.mark_email_read_outlined,
              text:
                  'Kode OTP digunakan untuk memastikan akun dibuat oleh pemilik email yang valid.',
            ),
            const SizedBox(height: AppSpacing.x3),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              enabled: !_isLoading,
              maxLength: 4,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                  ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                hintText: '0000',
                counterText: '',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              validator: (value) {
                final code = value?.trim() ?? '';

                if (code.isEmpty) {
                  return 'Kode OTP tidak boleh kosong';
                }

                if (code.length != 4) {
                  return 'Kode OTP harus 4 digit';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!_isLoading) {
                  _verify();
                }
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      _showSnack(
                        'Endpoint resend OTP belum tersedia. Silakan cek email kembali.',
                        isError: false,
                      );
                    },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kirim ulang kode'),
            ),
            const SizedBox(height: AppSpacing.x3),
            AuthPrimaryButton(
              label: 'Verifikasi',
              icon: Icons.verified_rounded,
              isLoading: _isLoading,
              onPressed: _verify,
            ),
          ],
        ),
      ),
    );
  }
}