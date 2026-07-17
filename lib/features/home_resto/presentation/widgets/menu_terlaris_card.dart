import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../recap_resto/data/recap_service.dart';
import '../../../recap_resto/presentation/widgets/menu_terlaris_card.dart' as RecapWidget;

class MenuTerlarisCard extends StatelessWidget {
  final String? restoId;

  const MenuTerlarisCard({Key? key, this.restoId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restoId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: RecapService.getRecapData(restoId!, 1), // 1 = Minggu Ini
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox();
        }

        final data = snapshot.data ?? {};
        final List<RecapWidget.MenuTerlarisItem> items =
            data['menuTerlaris'] ?? [];

        if (items.isEmpty) {
          return const SizedBox();
        }

        // Take top 3 for Home Dashboard
        final topItems = items.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Terlaris (Minggu Ini)',
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
                children: List.generate(topItems.length, (index) {
                  final item = topItems[index];
                  final isLast = index == topItems.length - 1;
                  Color rankColor = const Color(0xFFC4C4C4);
                  if (index == 0) rankColor = const Color(0xFFEFBF04);
                  if (index == 1) rankColor = const Color(0xFFC4C4C4);
                  if (index == 2) rankColor = const Color(0xFFCE8946);

                  return Column(
                    children: [
                      _buildMenuItem(
                        name: item.name,
                        sold: 'Terjual ${item.porsi} Porsi',
                        rank: '#${index + 1}',
                        rankColor: rankColor,
                      ),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child:
                              Divider(color: Color(0xFFEEEEEE), thickness: 1),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
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
