import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/custom_bottom_nav.dart';
import '../../../pendaftaran_resto/presentation/pages/validasi_diri_page.dart';
import '../../../pendaftaran_resto/presentation/pages/status_pendaftaran_page.dart';
import '../../../home_resto/presentation/pages/home_resto_page.dart';
import '../../../login/pages/login_page.dart';
import 'about_app_page.dart';
import 'security_privacy.dart';
import 'edit_profile_page.dart';
import '../widgets/menu_item.dart';

class CustomerProfilePage extends StatefulWidget {
  final VoidCallback? onBack;
  const CustomerProfilePage({super.key, this.onBack});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  int _currentIndex = 3; // Index for Profile
  String _userName = 'Jett Heartcliff';
  String _userEmail = 'babababamjett@gmail.com';
  String? _photoUrl;
  String? _photoBase64;
  String _buttonText = 'Daftar sebagai owner resto';
  bool _isOwner = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndRestoStatus();
  }

  Future<void> _loadUserAndRestoStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
      return;
    }

    try {
      // 1. Fetch user doc
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      String? role;
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          role = userData['role'] as String?;
          if (userData['nama'] != null) {
            _userName = userData['nama'] as String;
          }
          if (userData['email'] != null) {
            _userEmail = userData['email'] as String;
          }
          if (userData['photoUrl'] != null) {
            _photoUrl = userData['photoUrl'] as String;
          }
          if (userData['photoBase64'] != null) {
            _photoBase64 = userData['photoBase64'] as String;
          }
        }
      }

      final normalizedRole = role?.trim().toLowerCase();
      if (normalizedRole == 'owner' || normalizedRole == 'owner resto' || normalizedRole == 'owner_resto') {
        if (mounted) {
          setState(() {
            _isOwner = true;
            _buttonText = 'Masuk ke Dashboard Resto';
            _isLoadingStatus = false;
          });
        }
        return;
      }

      // 2. Fetch restaurant doc
      final querySnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isEmpty) {
            _buttonText = 'Daftar sebagai owner resto';
          } else {
            final restoData = querySnapshot.docs.first.data();
            final statusStr = (restoData['status'] as String?)?.trim().toLowerCase();
            if (statusStr == 'aktif') {
              _isOwner = true;
              _buttonText = 'Masuk ke Dashboard Resto';
            } else if (statusStr == 'rejected') {
              _buttonText = 'Pendaftaran Ditolak (Cek Detail)';
            } else {
              _buttonText = 'Menunggu Konfirmasi Pendaftaran';
            }
          }
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      _buildProfileCard(),
                      const SizedBox(height: 25),
                      _buildMenuSection(),
                      const SizedBox(height: 16),
                      _buildToggleSection(),
                      const SizedBox(height: 16),
                      _buildBecomeOwnerButton(),
                      const SizedBox(height: 16),
                      _buildLogoutButton(),
                      const SizedBox(height: 120), // Space for navbar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.pop(context),
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
                  horizontal: 45,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Profil',
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

  Widget _buildProfileCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: _photoBase64 != null
                            ? MemoryImage(base64Decode(_photoBase64!)) as ImageProvider
                            : (_photoUrl != null 
                                ? NetworkImage(_photoUrl!) as ImageProvider
                                : const AssetImage('assets/images/profile.png')),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _userEmail,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
          ProfileMenuItem(
            icon: Icons.person,
            title: 'Edit Profil',
            showDivider: true,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
              if (result == true) {
                _loadUserAndRestoStatus();
              }
            },
          ),
          ProfileMenuItem(
            icon: Icons.settings,
            title: 'Tentang App',
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutAppPage(),
                ),
              );
            },
          ),
          const ProfileMenuItem(
            icon: Icons.language,
            title: 'Bahasa',
            showDivider: true,
          ),
          ProfileMenuItem(
            icon: Icons.security,
            title: 'Keamanan/Privasi',
            showDivider: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityPrivacyPage(),
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }


  Widget _buildToggleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
          _buildToggleItem(
            icon: Icons.notifications,
            title: 'Notifikasi',
            value: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
          ),
          _buildToggleItem(icon: Icons.download, title: 'Update', value: true),
        ],
      ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          onChanged: (val) {},
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[400],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _checkRestoStatusAndNavigate() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum masuk/autentikasi!')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 1. Fetch user doc first to check role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;

      String? role;
      if (userDoc.exists) {
        role = userDoc.data()?['role'] as String?;
      }

      final normalizedRole = role?.trim().toLowerCase();
      if (normalizedRole == 'owner' || normalizedRole == 'owner resto' || normalizedRole == 'owner_resto') {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeRestoPage()),
        );
        return;
      }

      // 2. Otherwise check restaurant doc
      final querySnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (querySnapshot.docs.isEmpty) {
        // No restaurant registration, go to registration flow
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ValidasiDiriPage()),
        );
      } else {
        final restoData = querySnapshot.docs.first.data();
        final statusStr = (restoData['status'] as String?)?.trim().toLowerCase();

        if (statusStr == 'aktif') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeRestoPage()),
          );
        } else if (statusStr == 'rejected') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatusPendaftaranPage(
                initialStatus: RegistrationStatus.rejected,
              ),
            ),
          );
        } else {
          // default/pending
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatusPendaftaranPage(
                initialStatus: RegistrationStatus.pending,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  Widget _buildBecomeOwnerButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: ListTile(
        onTap: _checkRestoStatusAndNavigate,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 18),
        ),
        title: Text(
          _buttonText,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
