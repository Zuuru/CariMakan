import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/resto_bottom_navbar.dart';
import '../widgets/rekap_harian_card.dart';
import '../widgets/pesanan_aktif_card.dart';
import '../widgets/menu_terlaris_card.dart';

class HomeRestoPage extends StatefulWidget {
  const HomeRestoPage({Key? key}) : super(key: key);

  @override
  State<HomeRestoPage> createState() => _HomeRestoPageState();
}

class _HomeRestoPageState extends State<HomeRestoPage> {
  int _currentIndex = 0; // Default to 'Order/Dashboard'
  
  // Dummy Page Names for threshold testing
  final List<String> _pageNames = [
    'Dashboard / Recap',
    'Manajemen Menu',
    'Rekap / Keuangan',
    'Profil Resto'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Stack(
        children: [
          // Persistent stacked pages
          IndexedStack(
            index: _currentIndex,
            children: [
              // Page 0: Dashboard / Order
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: 120, // space for the floating navbar
                  ),
                  child: _buildDashboardContent(),
                ),
              ),
              // Page 1: Manajemen Menu
              _buildPlaceholderPage(1),
              // Page 2: Rekap / Keuangan
              _buildPlaceholderPage(2),
              // Page 3: Profil Resto
              _buildPlaceholderPage(3),
            ],
          ),
          
          // Floating Bottom Navbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: RestoBottomNavbar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        Text(
          'Halo!!',
          style: GoogleFonts.montserrat(
            fontSize: 48,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 30),
        const RekapHarianCard(),
        const SizedBox(height: 30),
        const PesananAktifCard(),
        const SizedBox(height: 30),
        const MenuTerlarisCard(),
      ],
    );
  }

  Widget _buildPlaceholderPage(int index) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 120,
          ),
          child: Text(
            'Halaman ${_pageNames[index]} Belum Tersedia',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Profile Picture Placeholder
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFFD9D9D9),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yo, Jett',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'Jl. Baskoro 38 Tembala...',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF989898),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
