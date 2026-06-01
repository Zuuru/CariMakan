import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/pendapatan_card.dart';
import '../widgets/trend_card.dart';
import '../widgets/menu_terlaris_card.dart';
import '../widgets/transaksi_terakhir_card.dart';

class RecapPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const RecapPage({Key? key, this.onBackPressed}) : super(key: key);

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  int _selectedPeriod = 1; // 0 = Hari Ini, 1 = Minggu Ini, 2 = Bulan Ini
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini'];

  // ─── Mock Data: Minggu Ini ──────────────────────────────────────────
  final List<TrendDataPoint> _weeklyTrend = const [
    TrendDataPoint(label: 'Sen', value: 1200000),
    TrendDataPoint(label: 'Sel', value: 900000),
    TrendDataPoint(label: 'Rab', value: 1500000),
    TrendDataPoint(label: 'Kam', value: 2100000),
    TrendDataPoint(label: 'Jum', value: 3550000),
    TrendDataPoint(label: 'Sab', value: 2800000),
    TrendDataPoint(label: 'Min', value: 2200000),
  ];

  final List<TrendDataPoint> _dailyTrend = const [
    TrendDataPoint(label: '08', value: 350000),
    TrendDataPoint(label: '10', value: 600000),
    TrendDataPoint(label: '12', value: 1200000),
    TrendDataPoint(label: '14', value: 900000),
    TrendDataPoint(label: '16', value: 450000),
    TrendDataPoint(label: '18', value: 800000),
    TrendDataPoint(label: '20', value: 550000),
  ];

  final List<TrendDataPoint> _monthlyTrend = const [
    TrendDataPoint(label: 'Jan', value: 22000000),
    TrendDataPoint(label: 'Feb', value: 18000000),
    TrendDataPoint(label: 'Mar', value: 25000000),
    TrendDataPoint(label: 'Apr', value: 30000000),
    TrendDataPoint(label: 'Mei', value: 42000000),
    TrendDataPoint(label: 'Jun', value: 36000000),
  ];

  final List<MenuTerlarisItem> _menuTerlaris = const [
    MenuTerlarisItem(
      name: 'Ayam Geprek Sambal Korek',
      porsi: 142,
      totalPendapatan: 3550000,
    ),
    MenuTerlarisItem(
      name: 'Nasi Goreng Spesial',
      porsi: 98,
      totalPendapatan: 2450000,
    ),
    MenuTerlarisItem(
      name: 'Es Teh Manis Jumbo',
      porsi: 180,
      totalPendapatan: 900000,
    ),
    MenuTerlarisItem(
      name: 'Mie Goreng Jawa',
      porsi: 74,
      totalPendapatan: 1500000,
    ),
    MenuTerlarisItem(
      name: 'Sate Ayam Madura (10 Tus...',
      porsi: 60,
      totalPendapatan: 2400000,
    ),
  ];

  final List<TransaksiItem> _transaksiTerakhir = const [
    TransaksiItem(
      noTransaksi: '452',
      tipe: TipeTransaksi.dineIn,
      waktu: '14:20',
      total: 45000,
    ),
    TransaksiItem(
      noTransaksi: '451',
      tipe: TipeTransaksi.takeAway,
      waktu: '14:05',
      total: 120000,
    ),
    TransaksiItem(
      noTransaksi: '450',
      tipe: TipeTransaksi.dineIn,
      waktu: '13:45',
      total: 75000,
    ),
    TransaksiItem(
      noTransaksi: '449',
      tipe: TipeTransaksi.dineIn,
      waktu: '13:10',
      total: 32000,
    ),
  ];

  // ─── Computed data per period ───────────────────────────────────────
  double get _totalPendapatan {
    if (_selectedPeriod == 0) return 1200000;
    if (_selectedPeriod == 1) return 8450000;
    return 42000000;
  }

  int get _totalTransaksi {
    if (_selectedPeriod == 0) return 48;
    if (_selectedPeriod == 1) return 280;
    return 1240;
  }

  double get _dineIn {
    if (_selectedPeriod == 0) return 720000;
    if (_selectedPeriod == 1) return 5200000;
    return 26000000;
  }

  double get _takeAway {
    if (_selectedPeriod == 0) return 480000;
    if (_selectedPeriod == 1) return 3250000;
    return 16000000;
  }

  List<TrendDataPoint> get _trendData {
    if (_selectedPeriod == 0) return _dailyTrend;
    if (_selectedPeriod == 1) return _weeklyTrend;
    return _monthlyTrend;
  }

  String get _trendPeriodLabel {
    return _periods[_selectedPeriod];
  }

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
              child: SingleChildScrollView(
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
                      totalPendapatan: _totalPendapatan,
                      totalTransaksi: _totalTransaksi,
                      dineIn: _dineIn,
                      takeAway: _takeAway,
                    ),
                    const SizedBox(height: 16),

                    // Card Trend
                    TrendCard(
                      dataPoints: _trendData,
                      period: _trendPeriodLabel,
                    ),
                    const SizedBox(height: 16),

                    // Card Menu Terlaris
                    MenuTerlarisCard(items: _menuTerlaris),
                    const SizedBox(height: 16),

                    // Card Transaksi Terakhir
                    TransaksiTerakhirCard(
                      transactions: _transaksiTerakhir,
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
                        ? const Color(0xFFB72B31)
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
                      ? const Color(0xFFB72B31)
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
