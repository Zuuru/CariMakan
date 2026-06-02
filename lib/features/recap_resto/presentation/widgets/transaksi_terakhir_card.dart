import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TipeTransaksi { dineIn, takeAway }

class TransaksiItem {
  final String noTransaksi;
  final TipeTransaksi tipe;
  final String waktu;
  final double total;

  const TransaksiItem({
    required this.noTransaksi,
    required this.tipe,
    required this.waktu,
    required this.total,
  });
}

class TransaksiTerakhirCard extends StatelessWidget {
  final List<TransaksiItem> transactions;
  final VoidCallback? onLihatSemua;

  const TransaksiTerakhirCard({
    Key? key,
    required this.transactions,
    this.onLihatSemua,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Transaksi Terakhir',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onLihatSemua,
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB72B31),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Transactions list
          ...transactions.asMap().entries.map((entry) {
            final int index = entry.key;
            final TransaksiItem trx = entry.value;
            final bool isLast = index == transactions.length - 1;

            return Column(
              children: [
                _buildTransaksiRow(trx),
                if (!isLast)
                  Divider(
                    height: 20,
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

  Widget _buildTransaksiRow(TransaksiItem trx) {
    final bool isDineIn = trx.tipe == TipeTransaksi.dineIn;
    final Color tipeColor =
        isDineIn ? const Color(0xFF2196F3) : const Color(0xFFFF9800);
    final String tipeLabel = isDineIn ? 'Dine In' : 'Take Away';

    return Row(
      children: [
        // Check icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Transaction info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${trx.noTransaksi}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tipeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      tipeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tipeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                trx.waktu,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Total
        Text(
          _formatRupiah(trx.total),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ],
    );
  }
}
