import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/menu_card.dart';
import 'tambah_menu_page.dart';

class ManajemenMenuPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ManajemenMenuPage({Key? key, this.onBackPressed}) : super(key: key);

  @override
  State<ManajemenMenuPage> createState() => _ManajemenMenuPageState();
}

class ItemMenu {
  String id;
  String title;
  double price;
  bool isAvailable;
  String? imageUrl;
  String category;
  String description;

  ItemMenu({
    required this.id,
    required this.title,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.category = 'Makanan',
    this.description = '',
  });
}

class _ManajemenMenuPageState extends State<ManajemenMenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mejaController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = 'Semua';
  final List<String> _mejaList = ['Meja 01', 'Meja 02', 'Meja 03'];

  // Mock initial menus based on typical resto items with Unsplash high-fidelity images
  final List<ItemMenu> _menus = [
    ItemMenu(
      id: '1',
      title: 'Mie Ayam',
      price: 10000,
      isAvailable: true,
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
      category: 'Makanan',
      description: 'Mie dengan potongan ayam gurih dan bumbu khas.',
    ),
    ItemMenu(
      id: '2',
      title: 'Mie Ayam Pangsit',
      price: 12000,
      isAvailable: true,
      imageUrl: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
      category: 'Makanan',
      description: 'Mie ayam lezat ditambah dengan pangsit basah yang lembut.',
    ),
    ItemMenu(
      id: '3',
      title: 'Nasi Goreng Resto',
      price: 15000,
      isAvailable: true,
      imageUrl: 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500',
      category: 'Makanan',
      description: 'Nasi goreng khas restoran dengan bumbu rempah pilihan.',
    ),
    ItemMenu(
      id: '4',
      title: 'Es Teh Manis',
      price: 3000,
      isAvailable: false,
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
      category: 'Minuman',
      description: 'Minuman teh segar manis dengan es batu melimpah.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _mejaController.dispose();
    super.dispose();
  }

  // Format price helper (e.g. 10000 -> Rp 10.000)
  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  // Filtered menus based on live search input and category filter
  List<ItemMenu> get _filteredMenus {
    return _menus.where((menu) {
      final matchesSearch = menu.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedFilter == 'Semua' || menu.category == _selectedFilter;
      return matchesSearch && matchesCategory;
    }).toList();
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
                  Tab(text: 'Daftar Menu'),
                  Tab(text: 'Manajemen Meja'),
                ],
              ),
            ),

            // TabBar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Daftar Menu
                  _buildDaftarMenuTab(),

                  // Tab 2: Manajemen Meja
                  _buildManajemenMejaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: Padding(
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
      ),
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
          // Resto Profile Picture
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFED001E),
                width: 1.5,
              ),
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?img=33'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarMenuTab() {
    final menusToDisplay = _filteredMenus;

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
                  color: Colors.black.withOpacity(0.02),
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
                        color: const Color(0xFFED001E).withOpacity(0.15),
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

        // List View of Menu Cards
        Expanded(
          child: menusToDisplay.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 8,
                    bottom: 160, // Padding to avoid covering components by bottom navigation
                  ),
                  itemCount: menusToDisplay.length,
                  itemBuilder: (context, index) {
                    final menu = menusToDisplay[index];
                    return MenuCard(
                      key: ValueKey(menu.id),
                      title: menu.title,
                      price: _formatRupiah(menu.price),
                      imageUrl: menu.imageUrl,
                      isAvailable: menu.isAvailable,
                      onAvailabilityChanged: (val) {
                        setState(() {
                          menu.isAvailable = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Menu ${menu.title} sekarang ${val ? 'Tersedia' : 'Tidak Tersedia'}',
                              style: GoogleFonts.outfit(),
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1C1C1C),
                          ),
                        );
                      },
                      onEditPressed: () => _showEditMenuDialog(menu),
                      onDeletePressed: () => _showDeleteConfirmation(menu),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
                  color: Colors.black.withOpacity(0.03),
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
                  decoration: InputDecoration(
                    hintText: 'Contoh: Meja 01',
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
                  onPressed: () {
                    if (_mejaController.text.trim().isNotEmpty) {
                      setState(() {
                        _mejaList.add(_mejaController.text.trim());
                        _mejaController.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'QR Code berhasil digenerate',
                            style: GoogleFonts.outfit(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1C1C1C),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'Generate QR',
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
          
          _mejaList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Belum ada QR meja yang dibuat',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _mejaList.length,
                  itemBuilder: (context, index) {
                    final namaMeja = _mejaList[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
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
                                    namaMeja,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mejaList.removeAt(index);
                                    });
                                  },
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
                          // QR Code Placeholder
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 70,
                                  color: Color(0xFF1C1C1C),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Download Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Mengunduh QR Code $namaMeja...',
                                      style: GoogleFonts.outfit(),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF1C1C1C),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download_rounded, color: Color(0xFFED001E), size: 16),
                              label: Text(
                                'Download',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFED001E),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFED001E).withOpacity(0.1),
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
                ),
        ],
      ),
    );
  }

  Widget _buildPresetThumb(String url, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // Show Add Menu Page
  void _showAddMenuDialog() async {
    final newMenu = await Navigator.push<ItemMenu>(
      context,
      MaterialPageRoute(
        builder: (context) => const TambahMenuPage(),
      ),
    );

    if (newMenu != null) {
      setState(() {
        _menus.add(newMenu);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu ${newMenu.title} berhasil ditambahkan!',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFED001E),
        ),
      );
    }
  }

  // Show Edit Menu Page
  void _showEditMenuDialog(ItemMenu menu) async {
    final updatedMenu = await Navigator.push<ItemMenu>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahMenuPage(menu: menu),
      ),
    );

    if (updatedMenu != null) {
      setState(() {
        menu.title = updatedMenu.title;
        menu.price = updatedMenu.price;
        menu.imageUrl = updatedMenu.imageUrl;
        menu.category = updatedMenu.category;
        menu.description = updatedMenu.description;
        menu.isAvailable = updatedMenu.isAvailable;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu ${updatedMenu.title} berhasil diperbarui!',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFED001E),
        ),
      );
    }
  }

  // Show Delete Confirmation Modal
  void _showDeleteConfirmation(ItemMenu menu) {
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
            'Apakah Anda yakin ingin menghapus menu "${menu.title}"?',
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
              onPressed: () {
                setState(() {
                  _menus.removeWhere((item) => item.id == menu.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Menu "${menu.title}" berhasil dihapus!',
                      style: GoogleFonts.outfit(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFFED001E),
                  ),
                );
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
