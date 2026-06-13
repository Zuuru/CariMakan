import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../widgets/card_pesanan.dart';
import 'tracker_takeaway_page.dart';
import 'tracker_dine_in_page.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class _OrderData {
  final String id;
  final PesananStatus status;
  final String restoName;
  final String itemName;
  final String time;
  final OrderType orderType;
  final String imageUrl;
  final Widget nextPage;
  final String statusRaw;

  const _OrderData({
    required this.id,
    required this.status,
    required this.restoName,
    required this.itemName,
    required this.time,
    required this.orderType,
    required this.imageUrl,
    required this.nextPage,
    required this.statusRaw,
  });
}

class PesananPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PesananPage({super.key, this.onBack});

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PesananStatus _statusFilter = PesananStatus.process;
  OrderType? _orderTypeFilter;

  Map<String, Map<String, dynamic>> _restaurants = {};
  bool _loadingRestos = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadRestaurants() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('restaurants').get();
      final temp = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        temp[doc.id] = doc.data();
      }
      if (mounted) {
        setState(() {
          _restaurants = temp;
          _loadingRestos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRestos = false;
        });
      }
    }
  }

  String _formatOrderTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    final DateTime date = timestamp.toDate().toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime orderDay = DateTime(date.year, date.month, date.day);

    if (orderDay == today) {
      return DateFormat('HH.mm').format(date);
    } else if (orderDay == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_OrderData> _getFilteredOrders(List<_OrderData> allOrders) {
    return allOrders.where((order) {
      // 1. Status Filter
      if (order.status != _statusFilter) return false;

      // 2. Order Type Filter (Dine In / Takeaway)
      if (_orderTypeFilter != null && order.orderType != _orderTypeFilter) {
        return false;
      }

      // 3. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchResto = order.restoName.toLowerCase().contains(query);
        final matchItem = order.itemName.toLowerCase().contains(query);
        if (!matchResto && !matchItem) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _statusFilter = PesananStatus.process;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _statusFilter == PesananStatus.process
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: _statusFilter == PesananStatus.process
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sedang Proses',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _statusFilter == PesananStatus.process
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _statusFilter = PesananStatus.complete;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _statusFilter == PesananStatus.complete
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: _statusFilter == PesananStatus.complete
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pesanan Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _statusFilter == PesananStatus.complete
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('Silakan login terlebih dahulu untuk melihat pesanan Anda.'),
        ),
      );
    }

    if (_loadingRestos) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final List<_OrderData> allOrders = [];
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA); // Descending (most recent first)
          });

          for (var doc in sortedDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final restoId = data['resto_id'] ?? '';
            final restoData = _restaurants[restoId];
            final restoName = restoData?['nama'] ?? restoData?['name'] ?? 'Resto';

            String? imageUrl;
            String itemName = data['menuName'] ?? '';
            final items = data['items'] as List?;

            if (items != null && items.isNotEmpty) {
              // 1. Ambil gambar dari menu pertama yang dipesan
              imageUrl = items.first['menuImage'] as String?;
              
              // 2. Jika menuName kosong, kita construct dari list items
              if (itemName.isEmpty) {
                if (items.length == 1) {
                  itemName = items.first['menuName'] ?? 'Menu Makanan';
                } else {
                  itemName = '${items.first['menuName']} + ${items.length - 1} item';
                }
              }
            }

            // Jika tidak ada gambar menu, gunakan foto profil resto, atau gambar default sementara
            if (imageUrl == null || imageUrl.isEmpty) {
              imageUrl = restoData?['foto_profil'] as String?;
            }
            imageUrl ??= 'assets/images/background/bg 2.png'; // Placeholder sementara yang ada di project

            if (itemName.isEmpty) {
               itemName = 'Pesanan';
            }

            final statusRaw = data['status'] ?? 'paid';
            final status = (statusRaw == 'Selesai')
                ? PesananStatus.complete
                : PesananStatus.process;

            final typeStr = data['type'] ?? 'Dine In';
            final orderType = (typeStr == 'Take Away')
                ? OrderType.takeAway
                : OrderType.dineIn;

            final timeStr = _formatOrderTime(data['orderDate'] as Timestamp?);

            final Widget nextPage = (orderType == OrderType.takeAway)
                ? TrackerTakeawayPage(orderId: doc.id)
                : TrackerDineInPage(orderId: doc.id);

            allOrders.add(_OrderData(
              id: doc.id,
              status: status,
              restoName: restoName,
              itemName: data['menuName'] ?? '',
              time: timeStr,
              orderType: orderType,
              imageUrl: imageUrl,
              nextPage: nextPage,
              statusRaw: statusRaw,
            ));
          }
        }

        final filtered = _getFilteredOrders(allOrders);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header with Back Button, Search, and Filters
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomBackButton(onPressed: widget.onBack),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Pesanan',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Search Bar (Full Width)
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari pesanan...',
                            hintStyle: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Major Filter (Sedang Proses & Pesanan Selesai)
                      _buildStatusFilter(),
                      const SizedBox(height: 15),

                      // Mini Filter (Dine In & Takeaway)
                      Row(
                        children: [
                          _buildMiniFilterChip(
                            label: 'Dine In',
                            icon: Icons.restaurant,
                            isSelected: _orderTypeFilter == OrderType.dineIn,
                            onTap: () {
                              setState(() {
                                if (_orderTypeFilter == OrderType.dineIn) {
                                  _orderTypeFilter = null;
                                } else {
                                  _orderTypeFilter = OrderType.dineIn;
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildMiniFilterChip(
                            label: 'Takeaway',
                            icon: Icons.shopping_bag,
                            isSelected: _orderTypeFilter == OrderType.takeAway,
                            onTap: () {
                              setState(() {
                                if (_orderTypeFilter == OrderType.takeAway) {
                                  _orderTypeFilter = null;
                                } else {
                                  _orderTypeFilter = OrderType.takeAway;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Divider
                Divider(color: Colors.grey[300], thickness: 1, height: 1),

                // List of Orders / Empty State
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada pesanan ditemukan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Coba ubah kata kunci atau filter Anda',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => order.nextPage,
                                  ),
                                );
                              },
                              child: CardPesanan(
                                status: order.status,
                                restoName: order.restoName,
                                itemName: order.itemName,
                                time: order.time,
                                orderType: order.orderType,
                                imageUrl: order.imageUrl,
                                statusText: order.statusRaw,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
