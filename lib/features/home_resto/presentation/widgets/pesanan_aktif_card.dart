import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PesananAktifCard extends StatelessWidget {
  const PesananAktifCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pesanan Aktif',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // Item 1
        _buildPesananItem(
          queueNumber: '#10',
          type: 'Dine In',
          typeColor: const Color(0xFFE31B23),
          tableInfo: 'Meja 01',
          items: ['2x Mie Ayam', '2x Es Teh', '1x Pangsit Goreng'],
          statusText: 'Proses',
          statusColor: const Color(0xFFE31B23),
        ),
        const SizedBox(height: 12),
        // Item 2
        _buildPesananItem(
          queueNumber: '#10',
          type: 'Take Away',
          typeColor: const Color(0xFFFF8800),
          tableInfo: 'Meja 01',
          items: ['2x Mie Ayam', '2x Es Teh', '1x Pangsit Goreng'],
          statusText: 'Selesai',
          statusColor: const Color(0xFF61CF61),
        ),
      ],
    );
  }

  Widget _buildPesananItem({
    required String queueNumber,
    required String type,
    required Color typeColor,
    required String tableInfo,
    required List<String> items,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
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
          // Queue Number Box
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFC0C0C0),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              queueNumber,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tableInfo,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C7C7C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    item,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7C7C7C),
                    ),
                  ),
                )),
              ],
            ),
          ),
          // Status Button
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
