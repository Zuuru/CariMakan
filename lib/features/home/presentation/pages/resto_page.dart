import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'detail_menu_page.dart';
import '../../../pesanan/data/cart_service.dart';
import '../../../pesanan/presentation/pages/pembayaran_page.dart';

class RestoPage extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String distance;
  final int queueCount;
  final String? tableId;
  final String? nomorMeja;
  final String restoId;

  const RestoPage({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.distance,
    required this.queueCount,
    this.tableId,
    this.nomorMeja,
    required this.restoId,
  });

  @override
  State<RestoPage> createState() => _RestoPageState();
}

class _RestoPageState extends State<RestoPage> {
  String _selectedCategory = 'Makanan';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // State for operational hours and queue
  bool _isOpen = true;
  String _operationalHoursDisplay = 'Loading...';
  int _activeQueueCount = 0;

  @override
  void initState() {
    super.initState();
    _activeQueueCount = widget.queueCount;
    _listenOperationalHours();
    _listenActiveOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listenOperationalHours() {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayStr = days[DateTime.now().weekday - 1];

    FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restoId)
        .collection('operational_hours')
        .doc(todayStr)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final bool isActive = data['isOpen'] ?? data['is_active'] ?? false;
        final String openTime = data['openTime'] ?? data['open_time'] ?? '00:00';
        final String closeTime = data['closeTime'] ?? data['close_time'] ?? '23:59';

        bool currentlyOpen = false;
        if (isActive) {
          final now = TimeOfDay.now();
          final openTimeParts = openTime.split(':');
          final closeTimeParts = closeTime.split(':');
          if (openTimeParts.length == 2 && closeTimeParts.length == 2) {
            final oTime = TimeOfDay(hour: int.tryParse(openTimeParts[0]) ?? 0, minute: int.tryParse(openTimeParts[1]) ?? 0);
            final cTime = TimeOfDay(hour: int.tryParse(closeTimeParts[0]) ?? 0, minute: int.tryParse(closeTimeParts[1]) ?? 0);

            final nowDouble = now.hour + now.minute / 60.0;
            final openDouble = oTime.hour + oTime.minute / 60.0;
            final closeDouble = cTime.hour + cTime.minute / 60.0;

            if (closeDouble < openDouble) {
              currentlyOpen = nowDouble >= openDouble || nowDouble <= closeDouble;
            } else {
              currentlyOpen = nowDouble >= openDouble && nowDouble <= closeDouble;
            }
          }
        }

        if (mounted) {
          setState(() {
            _isOpen = currentlyOpen;
            _operationalHoursDisplay = isActive ? '$openTime-$closeTime' : 'Libur';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isOpen = false;
            _operationalHoursDisplay = 'Libur';
          });
        }
      }
    });
  }

  void _listenActiveOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('resto_id', isEqualTo: widget.restoId)
        .where('status', whereIn: ['paid', 'processing'])
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeQueueCount = snapshot.docs.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Center(child: CustomBackButton()),
        ),
        title: Text(
          widget.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite_border, size: 20, color: Colors.black),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
          if (widget.nomorMeja != null && widget.nomorMeja!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: const Color(0xFFED001E),
              child: Row(
                children: [
                  const Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Anda Terhubung di Meja ${widget.nomorMeja}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Sesi Aktif',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Resto Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.imageUrl.isEmpty
                        ? Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                          )
                        : widget.imageUrl.startsWith('http')
                            ? Image.network(
                                widget.imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                                ),
                              )
                            : Image.asset(
                                widget.imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                                ),
                              ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE30613), // Red
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '4.9 (999)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              Text(
                'Jl. Setia Budi No.28, Ngesrep, Kec. Banyumanik, Kota Semarang, Jawa Tengah 50262',
                style: GoogleFonts.poppins(
                  color: Colors.grey[800],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Status & Queue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOpen ? 'Buka' : 'Tutup',
                        style: GoogleFonts.poppins(
                          color: _isOpen ? const Color(0xFF2E8104) : Colors.red,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _operationalHoursDisplay,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB), // Pinkish
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$_activeQueueCount',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'antrean',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tags
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildTag(Icons.location_on, widget.distance, Colors.red),
                  _buildTag(Icons.thumb_up_alt_outlined, 'Kopi & Dessert', Colors.green),
                  _buildTag(Icons.star, 'Top Tier Resto', Colors.orange),
                  _buildTag(Icons.star, 'Top Tier Resto', Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Cari makanan/minuman Kamu nyakk',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    prefixIcon: const Icon(Icons.search, color: Colors.black87),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.black87),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Menu Gacorr!
              Text(
                'Menu Gacorr!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 230,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menus')
                      .where('resto_id', isEqualTo: widget.restoId)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE30613)),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final rawPrice = (data['harga'] ?? 0).toDouble();
                          
                          // format price
                          final String valStr = rawPrice.toInt().toString();
                          final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                          final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
                          final priceStr = 'Rp $formatted';

                          return _buildMenuCard(
                            doc.id,
                            data['nama'] ?? 'Unknown',
                            priceStr,
                            data['image_url'] ?? 'assets/images/placeholder.jpg',
                            rawPrice: rawPrice,
                          );
                        },
                      );
                    }
                    return Center(
                      child: Text(
                        'Belum ada menu',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Filter Tags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Makanan', 'Minuman', 'Snack', 'Paket'].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE30613) : Colors.transparent,
                            border: Border.all(
                                color: isSelected ? const Color(0xFFE30613) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Filtered Content
              Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menus')
                      .where('resto_id', isEqualTo: widget.restoId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Color(0xFFE30613)),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final allDocs = snapshot.data!.docs;
                      final filteredDocs = allDocs.where((doc) {
                        final menu = doc.data() as Map<String, dynamic>;
                        final cat = menu['kategori'] as String? ?? 'Makanan';
                        final name = (menu['nama'] as String? ?? '').toLowerCase();
                        if (cat != _selectedCategory) return false;
                        if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) return false;
                        return true;
                      }).toList();

                      if (filteredDocs.isNotEmpty) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: filteredDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final rawPrice = (data['harga'] ?? 0).toDouble();
                            
                            // format price
                            final String valStr = rawPrice.toInt().toString();
                            final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                            final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
                            final priceStr = 'Rp $formatted';

                            return _buildMenuCard(
                              doc.id,
                              data['nama'] ?? 'Unknown',
                              priceStr,
                              data['image_url'] ?? 'assets/images/placeholder.jpg',
                              rawPrice: rawPrice,
                            );
                          }).toList(),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Menu tidak ditemukan',
                            style: GoogleFonts.poppins(color: Colors.grey.shade600),
                          ),
                        );
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Belum ada menu',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    ),
  ],
),
          // Floating Cart Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: ListenableBuilder(
              listenable: CartService.instance,
              builder: (context, child) {
                final totalItems = CartService.instance.getTotalItems(widget.restoId);
                if (totalItems == 0) return const SizedBox.shrink();
                
                final totalPrice = CartService.instance.getTotalPrice(widget.restoId);
                
                return GestureDetector(
                  onTap: () {
                     _showCartBottomSheet(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE30613),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalItems item',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Selesai pilih?',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _formatRupiah(totalPrice),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.shopping_cart, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ListenableBuilder(
          listenable: CartService.instance,
          builder: (context, child) {
            final items = CartService.instance.getItems(widget.restoId);
            final totalItems = CartService.instance.getTotalItems(widget.restoId);

            if (items.isEmpty) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: Text('Keranjang kosong')),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Keranjang Kamu',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        // build variant text
                        List<String> variantTexts = [];
                        item.selectedVariants.forEach((groupName, opts) {
                          if (opts.isNotEmpty) {
                            final itemNames = opts.map((e) => e['nama']).join(', ');
                            variantTexts.add('$groupName: $itemNames');
                          }
                        });
                        String variantText = variantTexts.isEmpty ? 'Tidak ada kustomisasi' : variantTexts.join('\n');

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.menuImage.startsWith('http')
                                ? Image.network(item.menuImage, width: 60, height: 60, fit: BoxFit.cover)
                                : Image.asset(item.menuImage, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (ctx, err, trace) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menuName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    variantText,
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatRupiah(item.totalPrice * item.quantity),
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    CartService.instance.updateQuantity(widget.restoId, item, item.quantity - 1);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                                    child: const Icon(Icons.remove, size: 16, color: Colors.black54),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${item.quantity}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    CartService.instance.updateQuantity(widget.restoId, item, item.quantity + 1);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE30613)),
                                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PembayaranPage(
                            cartItems: items,
                            restoId: widget.restoId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE30613),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: Text(
                      'Checkout ($totalItems item)',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildTag(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.5)),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(String menuId, String name, String price, String imagePath, {bool isVertical = false, double rawPrice = 0.0}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMenuPage(
              restoId: widget.restoId,
              menuId: menuId,
              restoName: widget.name,
              menuName: name,
              menuImage: imagePath,
              menuPrice: rawPrice > 0 ? rawPrice : double.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0,
              description: 'Espresso yang di mix dengan susu dan butter dengan rasa yang cukup manis dengan perpaduan butter, kopi dan susu',
            ),
          ),
        );
      },
      child: Container(
        width: isVertical ? double.infinity : 150,
        margin: isVertical ? const EdgeInsets.only(bottom: 16) : EdgeInsets.zero,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1), // Cream/Pinkish
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imagePath.isEmpty
                    ? Container(
                        height: 130,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey),
                      )
                    : imagePath.startsWith('http')
                        ? Image.network(
                            imagePath,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 130,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey),
                            ),
                          )
                        : Image.asset(
                            imagePath,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 130,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey),
                            ),
                          ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, size: 16, color: Colors.black54),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE30613), // Red
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        '4.9 (999)',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
   );
  }
}

