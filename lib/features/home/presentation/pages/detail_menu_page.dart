import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import '../../../pesanan/presentation/pages/pembayaran_page.dart';

class DetailMenuPage extends StatefulWidget {
  final String restoName;
  final String menuName;
  final String menuImage;
  final double menuPrice;
  final String description;

  const DetailMenuPage({
    Key? key,
    required this.restoName,
    required this.menuName,
    required this.menuImage,
    required this.menuPrice,
    required this.description,
  }) : super(key: key);

  @override
  State<DetailMenuPage> createState() => _DetailMenuPageState();
}

class _DetailMenuPageState extends State<DetailMenuPage> {
  String _selectedGula = 'Normal';
  String _selectedEs = 'Normal';
  
  bool _addBiscoff = false;
  int _espressoShots = 0;
  bool _addCaramel = false;

  bool _isAddedToCart = false;

  double get _totalPrice {
    double total = widget.menuPrice;
    if (_addBiscoff) total += 5000;
    if (_addCaramel) total += 4000;
    total += (_espressoShots * 6000);
    return total;
  }

  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
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
          widget.restoName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Image and Detail Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Container
                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.menuImage.startsWith('http')
                                  ? Image.network(
                                      widget.menuImage,
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      widget.menuImage,
                                      width: double.infinity,
                                      height: 140,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 0),
                      // Detail Container (Overlap slightly or just side by side, side-by-side with padding)
                      // According to the image, the red container is on the right, it has no left border radius
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE30613),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topLeft: Radius.circular(16), // Adjusting based on standard appearance
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.menuName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  widget.description,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 9,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.9 (999)',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gula Options
                  Text(
                    'Mau gula seberapa beb?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildOptionCircle('Gapake', _selectedGula == 'Gapake', () => setState(() => _selectedGula = 'Gapake')),
                      _buildOptionCircle('Dikit aja', _selectedGula == 'Dikit aja', () => setState(() => _selectedGula = 'Dikit aja')),
                      _buildOptionCircle('Normal', _selectedGula == 'Normal', () => setState(() => _selectedGula = 'Normal')),
                      _buildOptionCircle('Manis', _selectedGula == 'Manis', () => setState(() => _selectedGula = 'Manis')),
                      _buildOptionCircle('Diabetes', _selectedGula == 'Diabetes', () => setState(() => _selectedGula = 'Diabetes')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Es Options
                  Text(
                    'kalau esnya seberapa beb?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildOptionCircle('Anget', _selectedEs == 'Anget', () => setState(() => _selectedEs = 'Anget')),
                      _buildOptionCircle('Dikit aja', _selectedEs == 'Dikit aja', () => setState(() => _selectedEs = 'Dikit aja')),
                      _buildOptionCircle('Normal', _selectedEs == 'Normal', () => setState(() => _selectedEs = 'Normal')),
                      _buildOptionCircle('Banyak', _selectedEs == 'Banyak', () => setState(() => _selectedEs = 'Banyak')),
                      const SizedBox(width: 40), // Spacer for alignment
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add On Options
                  Text(
                    'Add On - Mau nambah apa?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Biskuit Biscoff
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biskuit Biscoff', style: GoogleFonts.poppins(fontSize: 12)),
                      GestureDetector(
                        onTap: () => setState(() => _addBiscoff = !_addBiscoff),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _addBiscoff ? const Color(0xFFE30613) : Colors.grey),
                          ),
                          child: _addBiscoff
                              ? const Center(child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE30613)))
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Espresso Shots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Espresso shots', style: GoogleFonts.poppins(fontSize: 12)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_espressoShots > 0) setState(() => _espressoShots--);
                            },
                            child: const Icon(Icons.remove, color: Color(0xFFE30613), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$_espressoShots',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(() => _espressoShots++),
                            child: const Icon(Icons.add, color: Color(0xFFE30613), size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Caramel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Caramel', style: GoogleFonts.poppins(fontSize: 12)),
                      GestureDetector(
                        onTap: () => setState(() => _addCaramel = !_addCaramel),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _addCaramel ? const Color(0xFFE30613) : Colors.grey),
                          ),
                          child: _addCaramel
                              ? const Center(child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE30613)))
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Footer Total & Add to Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total :',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatRupiah(_totalPrice),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAddedToCart = true;
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 16),
                        label: Text(
                          'Tambah ke Keranjang',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE30613),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Cart Bar (Bottom)
          if (_isAddedToCart)
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  // Pass order details to PembayaranPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PembayaranPage(
                        menuName: widget.menuName,
                        menuImage: widget.menuImage,
                        menuPrice: widget.menuPrice,
                        totalPrice: _totalPrice,
                        gula: _selectedGula,
                        es: _selectedEs,
                        addBiscoff: _addBiscoff,
                        addCaramel: _addCaramel,
                        espressoShots: _espressoShots,
                      ),
                    ),
                  );
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
                            '1 item',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.menuName,
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
                            _formatRupiah(_totalPrice),
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCircle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFE30613) : Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Center(
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFFE30613),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
