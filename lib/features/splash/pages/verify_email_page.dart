import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/presentation/pages/home_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isEmailVerified = false;
  bool _canResendEmail = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Check initial status
    _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      _sendVerificationEmail();

      // Poll every 3 seconds to check if the user verified their email
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    // Reload user to get latest status
    await FirebaseAuth.instance.currentUser?.reload();

    if (mounted) {
      setState(() {
        _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      });
    }

    if (_isEmailVerified) {
      _timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      if (mounted) {
        setState(() => _canResendEmail = false);
      }

      // Allow resending after 30 seconds
      await Future.delayed(const Duration(seconds: 30));
      
      if (mounted) {
        setState(() => _canResendEmail = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim email verifikasi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
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
                // Back button (Logout and return)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () async {
                      _timer?.cancel();
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.pop(context); // Go back to splash
                      }
                    },
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
                            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.mark_email_unread_rounded,
                                  color: Colors.white,
                                  size: 80,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  "VERIFIKASI\nEMAIL",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Link verifikasi sudah dikirim ke email kamu:\n${FirebaseAuth.instance.currentUser?.email}",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  "Menunggu konfirmasi otomatis...",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _canResendEmail ? _sendVerificationEmail : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      _canResendEmail ? "Kirim Ulang Email" : "Tunggu sebentar...",
                                      style: GoogleFonts.outfit(
                                        color: Colors.black,
                                        fontSize: 16,
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
}
