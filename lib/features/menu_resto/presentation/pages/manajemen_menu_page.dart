import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/menu_model.dart';
import '../../data/menu_service.dart';
import '../../data/table_model.dart';
import '../../data/table_service.dart';
import '../widgets/menu_card.dart';
import 'tambah_menu_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../promo/presentation/pages/manajemen_promo_page.dart';
import '../../../promo/presentation/pages/tambah_promo_page.dart';

class ManajemenMenuPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ManajemenMenuPage({Key? key, this.onBackPressed}) : super(key: key);

  @override
  State<ManajemenMenuPage> createState() => _ManajemenMenuPageState();
}

class _ManajemenMenuPageState extends State<ManajemenMenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mejaController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = 'Semua';
  bool _isGeneratingQR = false;
  int _currentTab = 0;

  // Firestore state
  String? _restoId;
  bool _isLoadingRestoId = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTab = _tabController.index;
      });
    });
    _loadRestoId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _mejaController.dispose();
    super.dispose();
  }

  /// Cari resto_id milik owner yang sedang login
  Future<void> _loadRestoId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _restoId = snapshot.docs.first.id;
          _isLoadingRestoId = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingRestoId = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRestoId = false);
    }
  }

  // Format price helper (e.g. 10000 -> Rp 10.000)
  String _formatRupiah(int value) {
    final String valStr = value.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),
            
            // Custom TabBar Container with bottom border
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFED001E),
                indicatorWeight: 3,
                labelColor: const Color(0xFFED001E),
                unselectedLabelColor: const Color(0xFF8E8E93),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Menu'),
                  Tab(text: 'Promo'),
                  Tab(text: 'Meja'),
                ],
              ),
            ),

            // TabBar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Menu
                  _buildDaftarMenuTab(),

                  // Tab 2: Promo
                  ManajemenPromoPage(isEmbedded: true),

                  // Tab 3: Meja
                  _buildManajemenMejaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: _currentTab == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0), // Elevate above the floating bottom navigation bar
              child: FloatingActionButton(
                onPressed: _showAddMenuDialog,
                backgroundColor: const Color(0xFFED001E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : _currentTab == 1
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 90.0),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      if (_restoId == null) return;
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TambahPromoPage(restoId: _restoId!),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFFED001E),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Buat Promo',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Back Button
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
          const Spacer(),
          // Restaurant Name
          Text(
            'Nama Resto',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildDaftarMenuTab() {
    if (_isLoadingRestoId) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFED001E)),
      );
    }

    if (_restoId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Resto tidak ditemukan',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pastikan akun Anda terdaftar sebagai owner resto',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar Section
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari menu',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFADADAD),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFADADAD),
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Category Filter Row
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: ['Semua', 'Makanan', 'Minuman', 'Snack', 'Paket'].map((category) {
              final isSelected = _selectedFilter == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = category;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFED001E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFED001E) : const Color(0xFFE5E5E5),
                      width: 1.2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFFED001E).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ] : null,
                  ),
                  child: Text(
                    category == 'Paket' ? 'Paket/Bundle' : category,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : const Color(0xFF555555),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // List View of Menu Cards — StreamBuilder dari Firestore
        Expanded(
          child: StreamBuilder<List<MenuModel>>(
            stream: MenuService.getMenusByResto(_restoId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFED001E)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat menu',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final allMenus = snapshot.data ?? [];
              
              // Client-side filter
              final filteredMenus = allMenus.where((menu) {
                final matchesSearch = menu.nama.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesCategory = _selectedFilter == 'Semua' || menu.kategori == _selectedFilter;
                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredMenus.isEmpty) {
                if (allMenus.isEmpty) {
                  return _buildEmptyStateNoMenu();
                }
                return _buildEmptyStateSearch();
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 8,
                  bottom: 160,
                ),
                itemCount: filteredMenus.length,
                itemBuilder: (context, index) {
                  final menu = filteredMenus[index];
                  return MenuCard(
                    key: ValueKey(menu.id),
                    title: menu.nama,
                    price: _formatRupiah(menu.harga),
                    imageUrl: menu.imageUrl,
                    isAvailable: menu.isAvailable,
                    menuId: menu.id,
                    onAvailabilityChanged: (val) async {
                      try {
                        await MenuService.toggleAvailability(menu.id, val);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menu ${menu.nama} sekarang ${val ? 'Tersedia' : 'Tidak Tersedia'}',
                                style: GoogleFonts.outfit(),
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF1C1C1C),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal update ketersediaan: $e', style: GoogleFonts.outfit()),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFED001E),
                            ),
                          );
                        }
                      }
                    },
                    onEditPressed: () => _showEditMenuDialog(menu),
                    onDeletePressed: () => _showDeleteConfirmation(menu),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateNoMenu() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFBEBEB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 40,
              color: Color(0xFFED001E),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada menu',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambahkan menu pertama',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateSearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Menu tidak ditemukan',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ketik kata kunci yang berbeda',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManajemenMejaTab() {
    if (_isLoadingRestoId) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFED001E)),
      );
    }

    if (_restoId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Gagal memuat data restoran. Pastikan Anda masuk sebagai Owner.',
            style: GoogleFonts.outfit(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 160,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian Buat QR Baru
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat QR Baru',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nomor Meja',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mejaController,
                  enabled: !_isGeneratingQR,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 01, 02A, 12',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFADADAD),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFED001E), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isGeneratingQR
                      ? null
                      : () async {
                          final nomorMeja = _mejaController.text.trim();
                          if (nomorMeja.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Nomor meja tidak boleh kosong!',
                                  style: GoogleFonts.outfit(),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFFED001E),
                              ),
                            );
                            return;
                          }

                          setState(() => _isGeneratingQR = true);
                          try {
                            final exists = await TableService.checkTableExists(_restoId!, nomorMeja);
                            if (exists) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Meja $nomorMeja sudah terdaftar!'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFFED001E),
                                  ),
                                );
                              }
                            } else {
                              await TableService.tambahMeja(_restoId!, nomorMeja);
                              _mejaController.clear();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('QR Code Meja $nomorMeja berhasil dibuat! 🎉'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal membuat meja: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isGeneratingQR = false);
                            }
                          }
                        },
                  icon: _isGeneratingQR
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isGeneratingQR ? 'Memproses...' : 'Generate QR',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED001E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Bagian Daftar Meja
          Text(
            'Daftar Meja',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<List<TableModel>>(
            stream: TableService.getTablesStream(_restoId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(color: Color(0xFFED001E)),
                  ),
                );
              }

              final tables = snapshot.data ?? [];

              if (tables.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Belum ada QR meja yang dibuat',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header (Nama Meja + Delete Icon)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4, top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Meja ${table.nomorMeja}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showDeleteMejaConfirmation(table),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFED001E),
                                  size: 20,
                                ),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // QR Code Render
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 90,
                                height: 90,
                                child: QrImageView(
                                  data: table.qrData,
                                  version: QrVersions.auto,
                                  size: 90.0,
                                  foregroundColor: const Color(0xFFED001E),
                                  gapless: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Download/View Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ElevatedButton.icon(
                            onPressed: () => _showQrPreviewDialog(table),
                            icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFFED001E), size: 16),
                            label: Text(
                              'Lihat QR',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFED001E),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFED001E).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFFED001E),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(double.infinity, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showQrPreviewDialog(TableModel table) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Meja ${table.nomorMeja}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: table.qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    foregroundColor: const Color(0xFFED001E),
                    gapless: false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pindai QR Code di atas menggunakan aplikasi CariMakan untuk memesan menu langsung dari meja ini.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED001E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteMejaConfirmation(TableModel table) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus Meja ${table.nomorMeja}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus Meja ${table.nomorMeja}?\nQR Code ini tidak akan bisa digunakan lagi.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await TableService.hapusMeja(_restoId!, table.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Meja ${table.nomorMeja} berhasil dihapus!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFED001E),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus meja: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFED001E),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED001E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show Add Menu Page
  void _showAddMenuDialog() async {
    if (_restoId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahMenuPage(restoId: _restoId!),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu berhasil ditambahkan! 🎉',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  // Show Edit Menu Page
  void _showEditMenuDialog(MenuModel menu) async {
    if (_restoId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahMenuPage(
          restoId: _restoId!,
          existingMenu: menu,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu ${menu.nama} berhasil diperbarui!',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  // Show Delete Confirmation Modal
  void _showDeleteConfirmation(MenuModel menu) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Hapus Menu',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus menu "${menu.nama}"?\n\nSemua kustomisasi yang terkait juga akan dihapus.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await MenuService.hapusMenu(menu.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Menu "${menu.nama}" berhasil dihapus!',
                          style: GoogleFonts.outfit(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFED001E),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus menu: $e', style: GoogleFonts.outfit()),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFED001E),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED001E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
