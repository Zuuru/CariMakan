import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../../../profile/presentation/pages/customer_profile_page.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/card_resto.dart';
import '../widgets/promo_banner.dart';
import '../widgets/icon_makanan.dart';
import '../widgets/user_points.dart';
import 'scan_page.dart';
import 'resto_page.dart';
import 'search_page.dart';
import 'location_picker_page.dart';
import '../../../promo/presentation/pages/promo_page.dart';
import '../../../pesanan/presentation/pages/pesanan_page.dart';
import 'package:carimakan/features/map/pages/map_screen.dart';
import '../widgets/mini_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(onProfileTap: () => setState(() => _currentIndex = 3)),
      PromoPage(onBack: () => setState(() => _currentIndex = 0)),
      PesananPage(onBack: () => setState(() => _currentIndex = 0)),
      CustomerProfilePage(onBack: () => setState(() => _currentIndex = 0)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final VoidCallback onProfileTap;
  const HomeContent({super.key, required this.onProfileTap});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _userName = 'Guest';
  String? _photoUrl;
  String? _photoBase64;
  String _userAddress = 'Mencari lokasi...';
  String? _customAddress;
  double? _customLat;
  double? _customLng;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenUserData();
    _loadLocation();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          final fullName = doc.data()?['nama'] as String? ?? 'Guest';
          // Ambil nama depan saja
          final firstName = fullName.split(' ').first;
          final photoUrl = doc.data()?['photoUrl'] as String?;
          final photoBase64 = doc.data()?['photoBase64'] as String?;
          if (mounted) {
            setState(() {
              _userName = firstName;
              _photoUrl = photoUrl;
              _photoBase64 = photoBase64;
            });
          }
        }
      });
    }
  }

  Future<void> _loadLocation() async {
    if (_customAddress != null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street ?? place.name}, ${place.subLocality ?? place.locality}';
        if (mounted && _customAddress == null) {
          setState(() {
            _userAddress = address;
          });
        }
      }
    } catch (e) {
      if (mounted && _customAddress == null) {
        setState(() {
          _userAddress = 'Gagal memuat lokasi';
        });
      }
    }
  }

  Future<void> _setCustomLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialAddress: (_userAddress == 'Mencari lokasi...' || _userAddress == 'Gagal memuat lokasi')
              ? null
              : _userAddress,
          initialLocation: (_customLat != null && _customLng != null)
              ? LatLng(_customLat!, _customLng!)
              : null,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _userAddress = result['address'] as String? ?? _userAddress;
        _customAddress = _userAddress;
        _customLat = result['latitude'] as double?;
        _customLng = result['longitude'] as double?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildGreeting(),
              const SizedBox(height: 15),
              _buildSearchBar(context),
              const SizedBox(height: 25),
              _buildPromotionSection(),
              const SizedBox(height: 25),
              _buildMapSection(context),
              const SizedBox(height: 25),
              const IconMakanan(),
              const SizedBox(height: 25),
              _buildNearbySection(context),
              const SizedBox(height: 200), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onProfileTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _setCustomLocation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yo, $_userName',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildHeaderIcon(Icons.notifications_none_outlined),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanPage()),
            );
          },
          child: _buildHeaderIcon(Icons.qr_code_scanner),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Icon(icon, size: 28, color: Colors.black);
  }

  Widget _buildGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Laper? ',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order / Cari',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'makan yukk',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        const UserPoints(),
      ],
    );
  }


  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchPage(),
            ),
          );
        },
        decoration: InputDecoration(
          hintText: 'Cari resto atau menu...',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildPromotionSection() {
    return const PromoBanner();
  }

  Widget _buildMapSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tempat makan terdekat dari kamu',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        MiniMapWidget(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNearbySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resto yang gacor nihh',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)));
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return CardResto(
                      imageUrl: data['imageUrl'] ?? data['foto_profil'] ?? 'https://via.placeholder.com/250x120',
                      name: data['nama'] ?? data['name'] ?? 'Unknown Resto',
                      distance: data['lokasi_alamat'] ?? data['distance'] ?? '-',
                      queueCount: data['queueCount'] ?? data['total_review'] ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestoPage(
                              name: data['nama'] ?? data['name'] ?? 'Unknown Resto',
                              imageUrl: data['imageUrl'] ?? data['foto_profil'] ?? 'https://via.placeholder.com/250x120',
                              distance: data['lokasi_alamat'] ?? data['distance'] ?? '-',
                              queueCount: data['queueCount'] ?? data['total_review'] ?? 0,
                              restoId: doc.id,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              }

              // Empty state
              return Center(
                child: Text(
                  'Belum ada resto yang terdaftar di area kamu nih',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
