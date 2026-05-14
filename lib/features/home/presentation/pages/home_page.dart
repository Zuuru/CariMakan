import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/pages/customer_profile_page.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/card_resto.dart';
import '../widgets/promo_banner.dart';
import '../widgets/icon_makanan.dart';
import 'scan_page.dart';
import 'resto_page.dart';

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
      const Center(child: Text('Promo Page')),
      const Center(child: Text('Pesanan Page')),
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

class HomeContent extends StatelessWidget {
  final VoidCallback onProfileTap;
  const HomeContent({super.key, required this.onProfileTap});

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
              _buildSearchBar(),
              const SizedBox(height: 25),
              _buildPromotionSection(),
              const SizedBox(height: 25),
              _buildMapSection(),
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
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: const AssetImage('assets/images/profile.png'),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yo, Jett',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            Text(
              'Jl. Baskoro 38 Tembala...',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
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
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
              decoration: InputDecoration(
                hintText: 'Cari makan atau tempat nih',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 50,
          width: 50,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPromotionSection() {
    return const PromoBanner();
  }

  Widget _buildMapSection() {
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
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
            image: const DecorationImage(
              image: NetworkImage('https://via.placeholder.com/400x200?text=Map+View+Placeholder'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 50,
                left: 100,
                child: _buildMapMarker(),
              ),
              Positioned(
                bottom: 60,
                right: 80,
                child: _buildMapMarker(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapMarker() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 12),
        ),
        Container(
          width: 2,
          height: 5,
          color: AppColors.primary,
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
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              CardResto(
                imageUrl: 'assets/images/ideologist.jpg',
                name: 'Ideologist Coffee And Social Space',
                distance: '2,14 km',
                queueCount: 4,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestoPage(
                        name: 'Ideologist Coffee And Social Space',
                        imageUrl: 'assets/images/ideologist.jpg',
                        distance: '2,14 km',
                        queueCount: 4,
                      ),
                    ),
                  );
                },
              ),
              CardResto(
                imageUrl: 'assets/images/parjo sipodang.jpg',
                name: 'Burjo Parjo Sipodang',
                distance: '0,95 km',
                queueCount: 8,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestoPage(
                        name: 'Burjo Parjo Sipodang',
                        imageUrl: 'assets/images/parjo sipodang.jpg',
                        distance: '0,95 km',
                        queueCount: 8,
                      ),
                    ),
                  );
                },
              ),
              CardResto(
                imageUrl: 'https://via.placeholder.com/250x120',
                name: 'Warmindo Berkah',
                distance: '1,2 km',
                queueCount: 2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestoPage(
                        name: 'Warmindo Berkah',
                        imageUrl: 'https://via.placeholder.com/250x120',
                        distance: '1,2 km',
                        queueCount: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
