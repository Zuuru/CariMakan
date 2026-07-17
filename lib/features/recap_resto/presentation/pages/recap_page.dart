import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/pendapatan_card.dart';
import '../widgets/trend_card.dart';
import '../widgets/menu_terlaris_card.dart';
import '../widgets/transaksi_terakhir_card.dart';
import '../../data/recap_service.dart';

class RecapPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const RecapPage({Key? key, this.onBackPressed}) : super(key: key);

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  int _selectedPeriod = 1; // 0 = Hari Ini, 1 = Minggu Ini, 2 = Bulan Ini
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── AppBar ───────────────────────────────────────────────
            _buildAppBar(),

            // ─── Period Filter Tabs ───────────────────────────────────
            _buildPeriodTabs(),

            // ─── Scrollable Content ───────────────────────────────────
            Expanded(
              child: FutureBuilder<String?>(
                future: RecapService.getCurrentRestoId(),
                builder: (context, restoIdSnapshot) {
                  if (restoIdSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final restoId = restoIdSnapshot.data;
                  if (restoId == null) {
                    return const Center(child: Text('Gagal mendapatkan Resto ID'));
                  }

                  return FutureBuilder<Map<String, dynamic>>(
                    future: RecapService.getRecapData(restoId, _selectedPeriod),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final data = snapshot.data ?? {};
                      final double totalPendapatan = data['totalPendapatan'] ?? 0.0;
                      final int totalTransaksi = data['totalTransaksi'] ?? 0;
                      final double dineIn = data['dineIn'] ?? 0.0;
                      final double takeAway = data['takeAway'] ?? 0.0;
                      final List<MenuTerlarisItem> menuTerlaris = data['menuTerlaris'] ?? [];
                      final List<TrendDataPoint> trendData = data['trendData'] ?? [];
                      final List<TransaksiItem> transaksiTerakhir = data['transaksiTerakhir'] ?? [];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: 120,
                        ),
                        child: Column(
                          children: [
                            // Card Pendapatan
                            PendapatanCard(
                              totalPendapatan: totalPendapatan,
                              totalTransaksi: totalTransaksi,
                              dineIn: dineIn,
                              takeAway: takeAway,
                            ),
                            const SizedBox(height: 16),

                            // Card Trend
                            TrendCard(
                              dataPoints: trendData,
                              period: _periods[_selectedPeriod],
                            ),
                            const SizedBox(height: 16),

                            // Card Menu Terlaris
                            if (menuTerlaris.isNotEmpty)
                              MenuTerlarisCard(items: menuTerlaris),
                            if (menuTerlaris.isNotEmpty)
                              const SizedBox(height: 16),

                            // Card Transaksi Terakhir
                            if (transaksiTerakhir.isNotEmpty)
                              TransaksiTerakhirCard(
                                transactions: transaksiTerakhir,
                                onLihatSemua: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lihat semua transaksi',
                                        style: GoogleFonts.outfit(),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF1C1C1C),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Laporan Penjualan',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final bool isSelected = _selectedPeriod == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFFD33400)
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _periods[index],
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFD33400)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
