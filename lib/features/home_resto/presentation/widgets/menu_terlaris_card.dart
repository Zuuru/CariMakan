import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuTerlarisCard extends StatelessWidget {
  const MenuTerlarisCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Terlaris',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(
                name: 'Es teh Manis',
                sold: 'Terjual 50 Porsi',
                rank: '#1',
                rankColor: const Color(0xFFEFBF04), // Yellow/Gold
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
              ),
              _buildMenuItem(
                name: 'Mie Ayam',
                sold: 'Terjual 25 Porsi',
                rank: '#2',
                rankColor: const Color(0xFFC4C4C4), // Silver
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
              ),
              _buildMenuItem(
                name: 'Pangsit Goreng',
                sold: 'Terjual 5 Porsi',
                rank: '#3',
                rankColor: const Color(0xFFCE8946), // Bronze
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String name,
    required String sold,
    required String rank,
    required Color rankColor,
  }) {
    return Row(
      children: [
        // Image Placeholder
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 16),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sold,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8C8C),
                ),
              ),
            ],
          ),
        ),
        // Rank
        Text(
          rank,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: rankColor,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
