import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'change_password.dart';

class SecurityPrivacyPage extends StatefulWidget {
  const SecurityPrivacyPage({super.key});

  @override
  State<SecurityPrivacyPage> createState() => _SecurityPrivacyPageState();
}

class _SecurityPrivacyPageState extends State<SecurityPrivacyPage> {
  bool isLocationEnabled = true;
  bool is2FAEnabled = false;

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Data Control'),
                        const SizedBox(height: 12),
                        _buildDataControlSection(),
                        
                        const SizedBox(height: 24),
                        _buildSectionTitle('Security'),
                        const SizedBox(height: 12),
                        _buildSecuritySection(),
                        
                        const SizedBox(height: 24),
                        _buildDeleteAccountSection(),
                        const SizedBox(height: 40),
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
                  horizontal: 35,
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
                  'Keamanan/Privasi',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDataControlSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: _buildItemCard(
        icon: Icons.location_on_outlined,
        iconBackgroundColor: const Color(0xFFE62129),
        title: 'Akses Lokasi',
        subtitle: 'Mengizinkan akses lokasi kamu',
        trailing: CupertinoSwitch(
          value: isLocationEnabled,
          activeColor: const Color(0xFFE62129),
          onChanged: (value) {
            setState(() {
              isLocationEnabled = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildItemCard(
            icon: Icons.vpn_key_outlined,
            iconBackgroundColor: const Color(0xFFE62129),
            title: 'Change Password',
            subtitle: 'Perbarui kata sandi/ ganti',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            icon: Icons.lock_outline,
            iconBackgroundColor: const Color(0xFFE62129),
            title: 'Two Factor Authentication',
            subtitle: 'Keamanan ekstra',
            trailing: CupertinoSwitch(
              value: is2FAEnabled,
              activeColor: const Color(0xFFE62129),
              onChanged: (value) {
                setState(() {
                  is2FAEnabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildItemCard(
            icon: Icons.smartphone,
            iconBackgroundColor: const Color(0xFFE62129),
            title: 'Aktivitas Login',
            subtitle: 'Lihat device mana yang kamu pake login',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: _buildItemCard(
        icon: Icons.delete_outline,
        iconBackgroundColor: const Color(0xFFEB5E5E),
        title: 'Hapus Akun',
        titleColor: const Color(0xFFEE2929),
        subtitle: 'Hapus permanen akun kamu',
      ),
    );
  }

  Widget _buildItemCard({
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ]
        ],
      ),
    ),
    );
  }
}
