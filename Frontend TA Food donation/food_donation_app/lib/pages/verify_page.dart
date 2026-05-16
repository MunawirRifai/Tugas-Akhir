import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class VerifyPage extends StatefulWidget {
  final String verificationToken;

  const VerifyPage({
    super.key,
    required this.verificationToken,
  });

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final codeController = TextEditingController();

  bool isLoading = false;

  Future<void> verify() async {

    if (codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP tidak boleh kosong'),
        ),
      );
      return;
    }

    try {

      setState(() {
        isLoading = true;
      });

      final response = await AuthService.verifyRegister(
        verificationToken: widget.verificationToken,
        code: codeController.text,
      );

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      if (response['success'] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi berhasil'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Verification failed',
            ),
          ),
        );
      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot connect to backend: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 30,
          ),

          child: Column(
            children: [

              const SizedBox(height: 40),

              const Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Kode OTP telah dikirim ke email kamu',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,

                decoration: InputDecoration(
                  hintText: '0000',
                  counterText: '',

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Silakan cek email kamu kembali',
                      ),
                    ),
                  );
                },

                child: const Text(
                  'Resend Code',
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: isLoading ? null : verify,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff8FD5A9),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
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