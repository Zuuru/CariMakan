import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final FocusNode _currentFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/bg 1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Kata sandi sekarang'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          hint: 'Masukkan password yang sekarang',
                          obscureText: _obscureCurrent,
                          focusNode: _currentFocus,
                          prefixIcon: Icons.lock,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureCurrent = !_obscureCurrent;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Kata sandi baru'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          hint: 'Masukkan kata sandi yang baru',
                          obscureText: _obscureNew,
                          focusNode: _newFocus,
                          prefixIcon: Icons.vpn_key,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Konfirmasi kata sandi baru'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          hint: 'Masukkan kata sandi yang baru',
                          obscureText: _obscureConfirm,
                          focusNode: _confirmFocus,
                          prefixIcon: Icons.vpn_key,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                        const SizedBox(height: 40),
                        _buildUpdateButton(),
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF99BDD5).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Ganti Kata Sandi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 44), // To balance the back button
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required bool obscureText,
    required FocusNode focusNode,
    required IconData prefixIcon,
    required VoidCallback onToggleVisibility,
  }) {
    final bool isFocused = focusNode.hasFocus;
    
    // Colors from design.yaml
    final Color backgroundColor = isFocused ? const Color(0xFFE7F0FA) : const Color(0xFFF1F1F1);
    final Color iconColor = isFocused ? const Color(0xFF1269CC) : const Color(0xFFED001E);
    final Color hintColor = isFocused ? const Color(0xFF1269CC).withOpacity(0.7) : Colors.black54;
    final Color textColor = isFocused ? const Color(0xFF1269CC) : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        focusNode: focusNode,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: hintColor,
            fontWeight: FontWeight.w300,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: iconColor,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggleVisibility,
            child: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: iconColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement update password logic
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFED001E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFED001E).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Update Password',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
