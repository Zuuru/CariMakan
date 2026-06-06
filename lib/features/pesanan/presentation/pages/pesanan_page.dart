import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../widgets/card_pesanan.dart';
import 'tracker_takeaway_page.dart';
import 'tracker_dine_in_page.dart';

class _OrderData {
  final PesananStatus status;
  final String restoName;
  final String itemName;
  final String time;
  final OrderType orderType;
  final String imageUrl;
  final Widget nextPage;

  const _OrderData({
    required this.status,
    required this.restoName,
    required this.itemName,
    required this.time,
    required this.orderType,
    required this.imageUrl,
    required this.nextPage,
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

  // List of all dummy orders
  late final List<_OrderData> _allOrders;

  @override
  void initState() {
    super.initState();
    _allOrders = [
      const _OrderData(
        status: PesananStatus.process,
        restoName: 'Ideologist Coffee And Social Space',
        itemName: '1x Butterscotch Sea Salt',
        time: '19.00',
        orderType: OrderType.takeAway,
        imageUrl: 'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
        nextPage: TrackerTakeawayPage(),
      ),
      const _OrderData(
        status: PesananStatus.complete,
        restoName: 'Ideologist Coffee And Social Space',
        itemName: '1x Butterscotch Sea Salt',
        time: '19.00',
        orderType: OrderType.dineIn,
        imageUrl: 'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
        nextPage: TrackerDineInPage(),
      ),
      const _OrderData(
        status: PesananStatus.process,
        restoName: 'Burjo Parjo Sipodang',
        itemName: '1x Nasi Goreng Spesial + Es Teh',
        time: '20.15',
        orderType: OrderType.dineIn,
        imageUrl: 'assets/images/parjo sipodang.jpg',
        nextPage: TrackerDineInPage(),
      ),
      const _OrderData(
        status: PesananStatus.complete,
        restoName: 'Burjo Parjo Sipodang',
        itemName: '2x Mie Dokdok Pedas',
        time: 'Kemarin',
        orderType: OrderType.takeAway,
        imageUrl: 'assets/images/parjo sipodang.jpg',
        nextPage: TrackerTakeawayPage(),
      ),
      const _OrderData(
        status: PesananStatus.complete,
        restoName: 'Warmindo Berkah',
        itemName: '1x Indomie Nyemek Jawa',
        time: '04 Jun',
        orderType: OrderType.dineIn,
        imageUrl: 'https://via.placeholder.com/250x120',
        nextPage: TrackerDineInPage(),
      ),
    ];

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_OrderData> get _filteredOrders {
    return _allOrders.where((order) {
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
    final filtered = _filteredOrders;

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
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
