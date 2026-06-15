import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Isi email dulu ya!';
      });
      return;
    }

    if (!RegExp(r"^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      setState(() {
        _emailError = 'Format email salah yakk!';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // Simulating network delay for Firebase process
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show Success dialog and return to Login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.black,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  "Link Terkirim!",
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Text(
              "Jika email terdaftar, link untuk mengatur ulang password telah dikirim ke $email. Silakan periksa inbox atau folder spam kamu.",
              style: GoogleFonts.outfit(color: const Color(0xFF4B5563), fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to LoginPage
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  "Kembali ke Login",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailError = 'Terjadi kesalahan. Coba lagi nanti.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Match the SplashPage3 background
          Image.asset(
            'assets/images/splash_screen/splash pic 3.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "LUPA\nPASSWORD?",
                                  style: GoogleFonts.outfit(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Jangan panik, masukkin email terdaftar kamu di bawah buat dapetin link reset password.",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Email Field Section
                                _buildLabel("Email"),
                                _buildTextField(
                                  "Masukkin email kamu yakk",
                                  controller: _emailController,
                                  enabled: !_isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                if (_emailError != null) _buildErrorText(_emailError!),
                                const SizedBox(height: 32),

                                // Button Kirim Link
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendResetLink,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Kirim Link Reset",
                                            style: GoogleFonts.outfit(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextEditingController? controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        error,
        style: GoogleFonts.outfit(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
