import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../recap_resto/data/recap_service.dart';

class RekapHarianCard extends StatelessWidget {
  final String? restoId;

  const RekapHarianCard({Key? key, this.restoId}) : super(key: key);

  String _formatRupiah(double value) {
    final formatCurrency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (restoId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: RecapService.getRekapHarian(restoId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        final incomeToday = (data['incomeToday'] as num?)?.toDouble() ?? 0;
        final ordersToday = (data['ordersToday'] as num?)?.toInt() ?? 0;
        final percentage = (data['percentage'] as num?)?.toDouble() ?? 0;

        String percentageText = '';
        if (percentage > 0) {
          percentageText = '+${percentage.toStringAsFixed(0)}% dari kemarin';
        } else if (percentage < 0) {
          percentageText = '${percentage.toStringAsFixed(0)}% dari kemarin';
        } else {
          percentageText = 'Sama dengan kemarin';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rekap Harianmu',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            // Pendapatan hari ini
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFD33400),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  // Background Icon
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Opacity(
                        opacity: 0.2,
                        child: Image.asset(
                          'assets/images/icon_home_resto/wallet.png',
                          width: 80,
                          height: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pendapatan hari ini',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(incomeToday),
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          percentageText,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Total Order
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFE3861B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  // Background Icon
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Opacity(
                        opacity: 0.2,
                        child: Image.asset(
                          'assets/images/icon_home_resto/list.png',
                          width: 70,
                          height: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Order',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$ordersToday',
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Order',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
