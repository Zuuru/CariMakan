import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'detail_menu_page.dart';

class RestoPage extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String distance;
  final int queueCount;
  final String? tableId;
  final String? nomorMeja;

  const RestoPage({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.distance,
    required this.queueCount,
    this.tableId,
    this.nomorMeja,
  });

  @override
  State<RestoPage> createState() => _RestoPageState();
}

class _RestoPageState extends State<RestoPage> {
  String _selectedCategory = 'Makanan';

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
      body: Column(
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
                    child: widget.imageUrl.startsWith('http')
                        ? Image.network(
                            widget.imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            widget.imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
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
                        'Open',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2E8104), // Green
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '12.00-23.00',
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
                          '${widget.queueCount}',
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Cari makanan/minuman Kamu nyakk',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    prefixIcon: const Icon(Icons.search, color: Colors.black87),
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
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildMenuCard(
                      'Butterscotch Sea Salt',
                      'Rp 37.000',
                      'assets/images/menu/minuman/images.jpg',
                      rawPrice: 37000.0,
                    ),
                    const SizedBox(width: 16),
                    _buildMenuCard(
                      'Chicken Cordon Bleu',
                      'Rp 45.000',
                      'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
                      rawPrice: 45000.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filter Tags
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'Makanan';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == 'Makanan' ? const Color(0xFFE30613) : Colors.transparent,
                        border: Border.all(
                            color: _selectedCategory == 'Makanan' ? const Color(0xFFE30613) : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Makanan',
                        style: GoogleFonts.poppins(
                          color: _selectedCategory == 'Makanan' ? Colors.white : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'Minuman';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == 'Minuman' ? const Color(0xFFE30613) : Colors.transparent,
                        border: Border.all(
                            color: _selectedCategory == 'Minuman' ? const Color(0xFFE30613) : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Minuman',
                        style: GoogleFonts.poppins(
                          color: _selectedCategory == 'Minuman' ? Colors.white : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filtered Content
              Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menus')
                      .where('restaurantName', isEqualTo: widget.name)
                      .where('category', isEqualTo: _selectedCategory)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Color(0xFFE30613)),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final rawPrice = (data['price'] ?? 0).toDouble();
                          
                          // format price
                          final String valStr = rawPrice.toInt().toString();
                          final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                          final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
                          final priceStr = 'Rp $formatted';

                          return _buildMenuCard(
                            data['name'] ?? 'Unknown',
                            priceStr,
                            data['imagePath'] ?? 'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
                            rawPrice: rawPrice,
                          );
                        }).toList(),
                      );
                    }
                    // Fallback to dummy data if empty or error
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        if (_selectedCategory == 'Makanan') ...[
                          _buildMenuCard(
                            'Chicken Cordon Bleu',
                            'Rp 45.000',
                            'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
                            rawPrice: 45000.0,
                          ),
                          _buildMenuCard(
                            'Chicken Cordon Bleu',
                            'Rp 45.000',
                            'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
                            rawPrice: 45000.0,
                          ),
                        ] else if (_selectedCategory == 'Minuman') ...[
                          _buildMenuCard(
                            'Butterscotch Sea Salt',
                            'Rp 37.000',
                            'assets/images/menu/minuman/images.jpg',
                            rawPrice: 37000.0,
                          ),
                          _buildMenuCard(
                            'Butterscotch Sea Salt',
                            'Rp 37.000',
                            'assets/images/menu/minuman/images.jpg',
                            rawPrice: 37000.0,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ],
),
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

  Widget _buildMenuCard(String name, String price, String imagePath, {bool isVertical = false, double rawPrice = 0.0}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMenuPage(
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
                child: Image.asset(
                  imagePath,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
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

