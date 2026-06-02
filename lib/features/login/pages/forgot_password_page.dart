import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _generatedOtp;

  String? _emailError;
  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Generates 6-digit random code
  void _sendOtp() {
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong yakk!';
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

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      final random = Random();
      final otp = (100000 + random.nextInt(900000)).toString();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _generatedOtp = otp;
        });

        // Beautiful glassmorphic/dark alert dialog showing the OTP
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              title: Text(
                "Kode OTP Terkirim (Demo)",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Kami mensimulasikan pengiriman OTP ke email kamu.",
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          otp,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF4D4D),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: otp));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kode OTP berhasil disalin!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Siap, Lanjut!",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _verifyOtp() {
    setState(() {
      _otpError = null;
    });

    final otpInput = _otpController.text.trim();
    if (otpInput.isEmpty) {
      setState(() {
        _otpError = 'Kode OTP tidak boleh kosong yakk!';
      });
      return;
    }

    if (otpInput != _generatedOtp) {
      setState(() {
        _otpError = 'Kode OTP salah yakk! Periksa kembali kodenya.';
      });
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 2; // Advance to Step 2
        });
      }
    });
  }

  void _saveNewPassword() {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password baru tidak boleh kosong!';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _passwordError = 'Password minimal harus 8 karakter yakk!';
      });
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() {
        _passwordError = 'Password harus mengandung minimal 1 huruf kapital yakk!';
      });
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() {
        _passwordError = 'Password harus mengandung minimal 1 angka yakk!';
      });
      return;
    }
    if (!RegExp(r'[!@#\$&*~_\-=\+]').hasMatch(password) && !RegExp(r'[^\w\s]').hasMatch(password)) {
      setState(() {
        _passwordError = 'Password harus mengandung minimal 1 simbol/karakter spesial yakk!';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Silakan konfirmasi password baru!';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Password konfirmasi tidak cocok!';
      });
      return;
    }

    setState(() => _isLoading = true);

    // Simulate backend password update
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show Success dialog and return to Login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              title: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFFFF4D4D),
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Password Diubah!",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Text(
                "Password kamu telah berhasil diubah. Silakan masuk kembali menggunakan password baru.",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to LoginPage
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      "Ke Halaman Login",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background/bg 1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Blur Layer + SafeArea content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Back Button & Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                "Lupa Password",
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 48), // Spacer to balance back button
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Subtitle step indicator
                          Text(
                            _currentStep == 1
                                ? "Langkah 1 dari 2: Verifikasi Email"
                                : "Langkah 2 dari 2: Buat Password Baru",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Animated switcher for switching steps
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: _currentStep == 1
                                ? _buildStepOneContent()
                                : _buildStepTwoContent(),
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
    );
  }

  Widget _buildStepOneContent() {
    return Column(
      key: const ValueKey(1),
      children: [
        _buildLabel("Email"),
        _buildTextField(
          "Masukkin email terdaftar kamu",
          controller: _emailController,
          enabled: !_isLoading,
        ),
        if (_emailError != null) _buildErrorText(_emailError!),
        const SizedBox(height: 20),

        // Kirim OTP / Verify fields
        if (_otpSent) ...[
          _buildLabel("Kode OTP"),
          _buildTextField(
            "Masukkin 6 digit OTP",
            controller: _otpController,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
          ),
          if (_otpError != null) _buildErrorText(_otpError!),
          const SizedBox(height: 32),

          // Button Verify OTP
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFFF4D4D), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Verifikasi OTP",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: Text(
              "Kirim ulang OTP",
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          // Button Kirim OTP
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFFF4D4D), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Kirim Kode OTP",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepTwoContent() {
    return Column(
      key: const ValueKey(2),
      children: [
        _buildLabel("Password Baru"),
        _buildTextField(
          "Password baru unik kamu",
          isPassword: true,
          obscureText: _obscureNewPassword,
          controller: _newPasswordController,
          enabled: !_isLoading,
          onToggleVisibility: () {
            setState(() {
              _obscureNewPassword = !_obscureNewPassword;
            });
          },
        ),
        if (_passwordError != null) _buildErrorText(_passwordError!),
        const SizedBox(height: 16),

        _buildLabel("Konfirmasi Password Baru"),
        _buildTextField(
          "Ulangi password baru kamu",
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          controller: _confirmPasswordController,
          enabled: !_isLoading,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        if (_confirmPasswordError != null) _buildErrorText(_confirmPasswordError!),
        const SizedBox(height: 32),

        // Button Simpan Password Baru
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Simpan Password Baru",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextEditingController? controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.grey,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 6),
        child: Text(
          error,
          style: GoogleFonts.outfit(
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
