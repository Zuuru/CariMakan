import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/order_karyawan_card.dart';
import '../widgets/order_detail_bottom_sheet.dart';
import '../pages/qr_scanner_page.dart';
import '../../../splash/pages/splash_screen.dart';

class KaryawanHomePage extends StatefulWidget {
  final String restoId;
  final String namaKaryawan;

  const KaryawanHomePage({
    Key? key,
    required this.restoId,
    required this.namaKaryawan,
  }) : super(key: key);

  @override
  State<KaryawanHomePage> createState() => _KaryawanHomePageState();
}

class _KaryawanHomePageState extends State<KaryawanHomePage> {
  // Tab State
  String _selectedTab = 'Dine In'; // 'Dine In' or 'Take Away'

  // Nama resto dari Firestore
  String _namaResto = 'Resto';

  @override
  void initState() {
    super.initState();
    _loadRestoName();
  }

  /// Load nama resto dari Firestore berdasarkan restoId
  Future<void> _loadRestoName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restoId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _namaResto = doc.data()?['nama'] ?? 'Resto';
        });
      }
    } catch (e) {
      // Gunakan default "Resto"
    }
  }

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
            Navigator.pop(context);
            _openQrScanner(order['id']);
          },
        );
      },
    );
  }

  void _updateOrderStatus(String id, String newStatus) {
    final Map<String, dynamic> updates = {
      'status': newStatus,
    };
    if (newStatus == 'Siap') {
      updates['readyAt'] = FieldValue.serverTimestamp();
    }

    FirebaseFirestore.instance.collection('orders').doc(id).update(updates).catchError((e) {
      _showSnackBar('Gagal memperbarui status: $e');
    });
  }

  void _removeOrder(String id) {
    FirebaseFirestore.instance.collection('orders').doc(id).update({
      'status': 'Selesai',
    }).catchError((e) {
      _showSnackBar('Gagal menyelesaikan pesanan: $e');
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

  void _openQrScanner(String orderId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerPage(
          restoId: widget.restoId,
          expectedOrderId: orderId,
        ),
      ),
    );
    if (result == true && mounted) {
      _showSnackBar('✅ Pesanan berhasil dikonfirmasi dan diserahkan!');
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SplashScreen(showLoginImmediately: true),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('resto_id', isEqualTo: widget.restoId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD33400)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada order $_selectedTab aktif',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    );
                  }

                  final List<Map<String, dynamic>> ordersList = [];
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final statusRaw = data['status'] ?? 'paid';

                    if (statusRaw == 'Selesai') continue;

                    String uiStatus = 'Menunggu';
                    if (statusRaw == 'Diproses') {
                      uiStatus = 'Diproses';
                    } else if (statusRaw == 'Siap') {
                      uiStatus = 'Siap';
                    }

                    final orderType = data['type'] ?? 'Dine In';
                    if (orderType != _selectedTab) continue;

                    final rawItems = data['items'] as List<dynamic>? ?? [];
                    final List<Map<String, dynamic>> itemsList = [];
                    for (final item in rawItems) {
                      if (item is Map) {
                        final customization = item['customization'] as Map<dynamic, dynamic>?;
                        final List<String> variantTexts = [];
                        if (customization != null) {
                          customization.forEach((groupName, opts) {
                            if (opts is List && opts.isNotEmpty) {
                              final itemNames = opts.map((e) {
                                if (e is Map) {
                                  return e['nama'] ?? '';
                                }
                                return '';
                              }).where((name) => name.isNotEmpty).join(', ');
                              if (itemNames.isNotEmpty) {
                                variantTexts.add('$groupName: $itemNames');
                              }
                            }
                          });
                        }
                        final String itemNote = variantTexts.join(', ');

                        itemsList.add({
                          'name': item['menuName'] ?? '',
                          'qty': item['quantity'] ?? 1,
                          'note': itemNote,
                        });
                      }
                    }

                    String timeDisplay = '';
                    final timestamp = data['orderDate'] as Timestamp?;
                    if (timestamp != null) {
                      final dt = timestamp.toDate().toLocal();
                      final hour = dt.hour.toString().padLeft(2, '0');
                      final minute = dt.minute.toString().padLeft(2, '0');
                      timeDisplay = '$hour:$minute';
                    } else {
                      final dt = DateTime.now();
                      final hour = dt.hour.toString().padLeft(2, '0');
                      final minute = dt.minute.toString().padLeft(2, '0');
                      timeDisplay = '$hour:$minute';
                    }

                    ordersList.add({
                      'id': doc.id,
                      'queueNumber': data['queueNumber'] ?? ('#' + doc.id.substring(doc.id.length - 2).toUpperCase()),
                      'type': orderType,
                      'tableOrPickupInfo': data['tableOrPickupInfo'] ?? '',
                      'time': timeDisplay,
                      'status': uiStatus,
                      'notes': '',
                      'items': itemsList,
                      'orderDate': timestamp,
                    });
                  }

                  ordersList.sort((a, b) {
                    final tA = a['orderDate'] as Timestamp?;
                    final tB = b['orderDate'] as Timestamp?;
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tA.compareTo(tB);
                  });

                  if (ordersList.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada order $_selectedTab aktif',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: ordersList.length,
                    itemBuilder: (context, index) {
                      final order = ordersList[index];
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Text(
                    widget.namaKaryawan.isNotEmpty
                        ? widget.namaKaryawan[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD33400),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _namaResto,
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
                        '${widget.namaKaryawan} (Karyawan)',
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
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFD33400)),
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
              color: Colors.black.withValues(alpha: 0.03),
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
                    color: _selectedTab == 'Dine In' ? const Color(0xFFD33400) : Colors.transparent,
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
                    color: _selectedTab == 'Take Away' ? const Color(0xFFD33400) : Colors.transparent,
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
