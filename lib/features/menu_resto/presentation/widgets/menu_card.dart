import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/menu_service.dart';
import '../../data/option_group_model.dart';

class MenuCard extends StatefulWidget {
  final String menuId;
  final String title;
  final String price;
  final String? imageUrl;
  final bool isAvailable;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const MenuCard({
    Key? key,
    required this.menuId,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.onAvailabilityChanged,
    required this.onEditPressed,
    required this.onDeletePressed,
  }) : super(key: key);

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  int _variantCount = 0;
  bool _isLoadingVariantCount = true;

  @override
  void initState() {
    super.initState();
    _loadVariantCount();
  }

  Future<void> _loadVariantCount() async {
    try {
      final groups = await MenuService.loadOptionGroupsWithItems(widget.menuId);
      if (mounted) {
        setState(() {
          _variantCount = groups.length;
          _isLoadingVariantCount = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVariantCount = false);
    }
  }

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
            color: Colors.black.withValues(alpha: 0.04),
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
              image: widget.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.imageUrl == null
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
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Menu Price and Variant Badge
                Row(
                  children: [
                    Text(
                      widget.price,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFED001E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_isLoadingVariantCount && _variantCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBEBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFED001E).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.build_circle_outlined, size: 10, color: Color(0xFFED001E)),
                            const SizedBox(width: 4),
                            Text(
                              '$_variantCount kustom',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFED001E),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
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
                          value: widget.isAvailable,
                          onChanged: widget.onAvailabilityChanged,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFED001E),
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
                        onTap: widget.onEditPressed,
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
                        onTap: widget.onDeletePressed,
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
                            color: Color(0xFFED001E),
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
