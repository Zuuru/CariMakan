import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuTerlarisItem {
  final String name;
  final int porsi;
  final double totalPendapatan;

  const MenuTerlarisItem({
    required this.name,
    required this.porsi,
    required this.totalPendapatan,
  });
}

class MenuTerlarisCard extends StatelessWidget {
  final List<MenuTerlarisItem> items;

  const MenuTerlarisCard({
    Key? key,
    required this.items,
  }) : super(key: key);

  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted =
        valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    // Rank colors: Gold, Silver, Bronze, then grey for the rest
    final List<Color> rankColors = [
      const Color(0xFFF5C518), // 1st - Gold
      const Color(0xFFB0BEC5), // 2nd - Silver
      const Color(0xFFCD7F32), // 3rd - Bronze
      const Color(0xFFBDBDBD), // 4th
      const Color(0xFFBDBDBD), // 5th
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFD33400),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Menu Terlaris',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // List items
          ...items.asMap().entries.map((entry) {
            final int index = entry.key;
            final MenuTerlarisItem item = entry.value;
            final Color rankColor = index < rankColors.length
                ? rankColors[index]
                : const Color(0xFFBDBDBD);
            final bool isLast = index == items.length - 1;

            return Column(
              children: [
                _buildMenuRow(
                  rank: index + 1,
                  rankColor: rankColor,
                  name: item.name,
                  porsi: item.porsi,
                  pendapatan: _formatRupiah(item.totalPendapatan),
                ),
                if (!isLast)
                  Divider(
                    height: 24,
                    thickness: 1,
                    color: const Color(0xFFF5F5F5),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required int rank,
    required Color rankColor,
    required String name,
    required int porsi,
    required String pendapatan,
  }) {
    return Row(
      children: [
        // Rank badge
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name and porsi
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1C1C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$porsi Porsi',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Pendapatan
        Text(
          pendapatan,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ],
    );
  }
}
