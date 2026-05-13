import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding luar agar navbar tidak menempel ke pinggir layar (floating effect)
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Hitam lebih pekat sesuai gambar
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10), // Padding dalam navbar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavItem(0, Icons.home_outlined, 'Home'),
          const SizedBox(width: 5),
          _buildNavItem(1, Icons.percent, 'Promo'),
          const SizedBox(width: 5),
          _buildNavItem(2, Icons.assignment_outlined, 'Pesanan'),
          const SizedBox(width: 5),
          _buildNavItem(3, Icons.person_outline, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = currentIndex == index;

    Widget navItem = GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedScale(
        scale: isActive ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          key: ValueKey('nav_item_$index'),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: isActive ? 18 : 0),
          width: isActive ? null : 56,
          constraints: BoxConstraints(
            minWidth: 56,
            maxWidth: isActive ? 160 : 56,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE30613) : const Color(0xFF262626),
            borderRadius: BorderRadius.circular(100),
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFFE30613).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: isActive ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isActive
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );

    return Flexible(
      flex: isActive ? 1 : 0,
      fit: isActive ? FlexFit.tight : FlexFit.loose,
      child: navItem,
    );
  }
}