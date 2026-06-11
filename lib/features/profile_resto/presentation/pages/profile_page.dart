import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';
import 'edit_profile_resto_page.dart';
import 'manajemen_karyawan_page.dart';
import '../../../splash/pages/splash_screen.dart';
import '../../../home/presentation/pages/home_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ProfilePage({super.key, this.onBackPressed});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _status;
  double _rating = 0.0;
  int _totalReview = 0;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadRestoProfile();
  }

  Future<void> _loadRestoProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Load user profile details
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        setState(() {
          _userName = userData?['nama'] as String?;
          _userEmail = userData?['email'] as String?;
        });
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final data = snapshot.docs.first.data();
        setState(() {
          _status = data['status'] as String?;
          _rating = (data['avg_rating'] as num?)?.toDouble() ?? 0.0;
          _totalReview = (data['total_review'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Widget _buildStatusBadge() {
    final status = _status?.trim().toLowerCase() ?? 'pending';
    Color badgeColor;
    Color textColor;
    IconData icon;
    String label;

    if (status == 'aktif') {
      badgeColor = const Color(0xFF10B981);
      textColor = const Color(0xFF10B981);
      icon = Icons.check_circle;
      label = 'Aktif';
    } else if (status == 'pending') {
      badgeColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFFF59E0B);
      icon = Icons.pending_actions;
      label = 'Pending';
    } else {
      badgeColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFEF4444);
      icon = Icons.cancel;
      label = 'Suspended';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAppBar(),
              const SizedBox(height: 30),
              
              // Profil Header
              _buildProfileHeader(),
              const SizedBox(height: 30),
              
              // Menu Actions (Profil, Resto, Promo)
              _buildMenuActions(context),
              const SizedBox(height: 16),
              
              // Menu Karyawan (Terpisah)
              _buildKaryawanMenu(context),
              const SizedBox(height: 30),
              
              // Informasi Resto
              _buildInformasiResto(),
              const SizedBox(height: 30),
              
              // Switch to Customer Button
              _buildSwitchToCustomerButton(context),
              const SizedBox(height: 16),
              
              // Logout Button
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        if (widget.onBackPressed != null)
          GestureDetector(
            onTap: widget.onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
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
          )
        else
          const SizedBox(width: 44),
        Expanded(
          child: Center(
            child: Text(
              'Profil Resto',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFED001E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFED001E).withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/Icon/icon_carimakan.png'), // placeholder
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userName ?? 'Memuat...',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userEmail ?? 'Memuat...',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              if (result == true) {
                _loadRestoProfile();
              }
            },
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildMenuItem(
            icon: Icons.storefront_outlined,
            title: 'Edit Profil Resto',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileRestoPage()),
              );
              if (result == true) {
                _loadRestoProfile();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKaryawanMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildMenuItem(
        icon: Icons.badge_outlined,
        title: 'Manajemen Karyawan',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManajemenKaryawanPage()),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFED001E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFED001E),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1C1C),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformasiResto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Resto',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rating',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_rating.toStringAsFixed(1)}/5.0',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1C1C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Review',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '$_totalReview Review',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchToCustomerButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFED001E), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: const Color(0xFFED001E),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz_rounded, size: 24),
            const SizedBox(width: 12),
            Text(
              'Kembali ke Menu Customer',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SplashScreen(showLoginImmediately: true),
              ),
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935), // Red
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 24),
            const SizedBox(width: 12),
            Text(
              'Keluar dari menu resto',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
