import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final String price;
  final String? imageUrl;
  final bool isAvailable;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const MenuCard({
    Key? key,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.onAvailabilityChanged,
    required this.onEditPressed,
    required this.onDeletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Rounded Image Placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(16),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(
                    Icons.fastfood_rounded,
                    color: Color(0xFFB0B0B0),
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Right: Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Menu Title
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Menu Price
                Text(
                  price,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB72B31),
                  ),
                ),
                const SizedBox(height: 4),
                // Bottom Controls Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // "Tersedia" label
                    Text(
                      'Tersedia',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Availability Switch
                    SizedBox(
                      height: 30,
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isAvailable,
                          onChanged: onAvailabilityChanged,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFB72B31),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD9D9D9),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Edit Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEditPressed,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDeletePressed,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFDEBED), // light pink/red background
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFB72B31),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
