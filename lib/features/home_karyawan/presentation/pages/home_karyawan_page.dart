import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:math';

import '../widgets/order_karyawan_card.dart';
import '../widgets/order_detail_bottom_sheet.dart';
import '../../../login/pages/login_page.dart'; // To navigate on logout
import '../../../splash/pages/splash_screen.dart';

class KaryawanHomePage extends StatefulWidget {
  const KaryawanHomePage({Key? key}) : super(key: key);

  @override
  State<KaryawanHomePage> createState() => _KaryawanHomePageState();
}

class _KaryawanHomePageState extends State<KaryawanHomePage> {
  // Tab State
  String _selectedTab = 'Dine In'; // 'Dine In' or 'Take Away'

  // Mock Data for Orders
  List<Map<String, dynamic>> _orders = [
    {
      'id': '1',
      'queueNumber': '#10',
      'type': 'Dine In',
      'tableOrPickupInfo': 'Meja 01',
      'time': '10:30',
      'status': 'Menunggu',
      'notes': 'Tolong es teh nya jangan terlalu manis.',
      'items': [
        {'name': 'Mie Ayam', 'qty': 2, 'note': ''},
        {'name': 'Es Teh', 'qty': 2, 'note': 'Sedikit gula'},
        {'name': 'Pangsit Goreng', 'qty': 1, 'note': ''},
      ]
    },
    {
      'id': '2',
      'queueNumber': '#11',
      'type': 'Take Away',
      'tableOrPickupInfo': '11:00',
      'time': '10:35',
      'status': 'Diproses',
      'notes': '',
      'items': [
        {'name': 'Nasi Goreng Spesial', 'qty': 1, 'note': 'Pedas level 3'},
        {'name': 'Es Jeruk', 'qty': 1, 'note': ''},
      ]
    },
    {
      'id': '3',
      'queueNumber': '#12',
      'type': 'Dine In',
      'tableOrPickupInfo': 'Meja 04',
      'time': '10:40',
      'status': 'Siap',
      'notes': '',
      'items': [
        {'name': 'Ayam Bakar Madu', 'qty': 3, 'note': ''},
        {'name': 'Nasi Putih', 'qty': 3, 'note': ''},
      ]
    },
    {
      'id': '4',
      'queueNumber': '#14',
      'type': 'Take Away',
      'tableOrPickupInfo': '12:15',
      'time': '10:50',
      'status': 'Menunggu',
      'notes': 'Minta tambahan sambal yang banyak.',
      'items': [
        {'name': 'Sate Ayam', 'qty': 2, 'note': 'Bumbu kacang pisah'},
      ]
    }
  ];

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return OrderDetailBottomSheet(
          orderData: order,
          onMulaiProses: () {
            _updateOrderStatus(order['id'], 'Diproses');
            Navigator.pop(context);
            _showSnackBar('Pesanan sedang diproses. Notifikasi dikirim ke customer.');
          },
          onTandaiSiap: () {
            _updateOrderStatus(order['id'], 'Siap');
            Navigator.pop(context);
            _showSnackBar('Pesanan siap! Notifikasi dikirim ke customer.');
          },
          onScanQR: () {
            // Simulate QR Scan process
            Navigator.pop(context);
            _showScannerMock(order['id']);
          },
        );
      },
    );
  }

  void _updateOrderStatus(String id, String newStatus) {
    setState(() {
      final index = _orders.indexWhere((o) => o['id'] == id);
      if (index != -1) {
        _orders[index]['status'] = newStatus;
      }
    });
  }

  void _removeOrder(String id) {
    setState(() {
      _orders.removeWhere((o) => o['id'] == id);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showScannerMock(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Membuka Kamera...', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Simulasi scan QR code pickup dari customer.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeOrder(id);
              _showSnackBar('QR Valid! Pesanan selesai dan diserahkan.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED001E)),
            child: Text('Simulasi Berhasil', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SplashScreen(showLoginImmediately: true),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter orders based on selected tab
    final filteredOrders = _orders.where((o) => o['type'] == _selectedTab).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada order $_selectedTab aktif',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return OrderKaryawanCard(
                          queueNumber: order['queueNumber'],
                          type: order['type'],
                          tableOrPickupInfo: order['tableOrPickupInfo'],
                          items: order['items'],
                          orderTime: order['time'],
                          status: order['status'],
                          onTap: () => _showOrderDetail(context, order),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/Icon/icon_carimakan.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resto Bintang 5',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), // Green active
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Budi (Karyawan)',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFED001E)),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 'Dine In'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 'Dine In' ? const Color(0xFFED001E) : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Dine In',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 'Dine In' ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 'Take Away'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 'Take Away' ? const Color(0xFFED001E) : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Take Away',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 'Take Away' ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
