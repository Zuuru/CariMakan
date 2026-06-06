import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestoBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const RestoBottomNavbar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0, 'assets/images/icon_navbar_resto/order.png', 'Order'),
          _buildNavItem(1, 'assets/images/icon_navbar_resto/menu.png', 'Menu'),
          _buildNavItem(2, 'assets/images/icon_navbar_resto/recap.png', 'Recap'),
          _buildNavItem(3, 'assets/images/icon_navbar_resto/profil.png', 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String imagePath, String label) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 54,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 20 : 0),
        width: isActive ? 140 : 54, // Expanded vs Circular
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFED001E) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular background for inactive state
            AnimatedOpacity(
              opacity: isActive ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFF353535),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content Row (Icon + Text)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                // Text inside a size animation
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: isActive ? null : 0,
                    child: Padding(
                      padding: EdgeInsets.only(left: isActive ? 8.0 : 0.0),
                      child: Text(
                        isActive ? label : '',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
