import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/features/order/checkout_page.dart';
import 'package:carimakan/features/order/cart_summary_bar.dart';

class DetailPesananPage extends StatefulWidget {
  final String name;
  final String price;
  final String imagePath;

  const DetailPesananPage({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
  });

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  // State pilihan kustomisasi menu
  String _selectedSugar = 'Normal';
  String _selectedIce = 'Normal';
  bool _isBiscoffChecked = false;
  bool _isCaramelChecked = false;
  int _espressoShots = 0;

  // Opsi pilihan
  final List<String> _sugarOptions = ['Gapake', 'Dikit aja', 'Normal', 'Manis', 'Diabetes'];
  final List<String> _iceOptions = ['Anget', 'Dikit aja', 'Normal', 'Banyak'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Detail Menu Utama
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      widget.imagePath,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE30613),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Espresso yang di mix dengan susu dan butter dengan rasa yang cukup manis...',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Kustomisasi Gula
            Text(
              'Mau gula seberapa beb?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sugarOptions.map((option) {
                bool isSelected = _selectedSugar == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSugar = option;
                      if (globalCart != null) {
                        _updateGlobalCart();
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE30613),
                            width: 2,
                          ),
                          color: isSelected ? const Color(0xFFE30613) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.circle, size: 10, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 2. Kustomisasi Es
            Text(
              'kalau esnya seberapa beb?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _iceOptions.map((option) {
                bool isSelected = _selectedIce == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIce = option;
                      if (globalCart != null) {
                        _updateGlobalCart();
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE30613),
                            width: 2,
                          ),
                          color: isSelected ? const Color(0xFFE30613) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.circle, size: 10, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 3. Add On Section
            Text(
              'Add On - Mau nambah apa?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                // Add-on: Biskuit Biscoff
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biskuit Biscoff',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBiscoffChecked = !_isBiscoffChecked;
                          if (globalCart != null) _updateGlobalCart();
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE30613), width: 2),
                          color: _isBiscoffChecked ? const Color(0xFFE30613) : Colors.transparent,
                        ),
                        child: _isBiscoffChecked
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add-on: Espresso Shots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Espresso shots',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_espressoShots > 0) {
                              setState(() {
                                _espressoShots--;
                                if (globalCart != null) _updateGlobalCart();
                              });
                            }
                          },
                          child: Text(
                            '—',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE30613),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            '$_espressoShots',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _espressoShots++;
                              if (globalCart != null) _updateGlobalCart();
                            });
                          },
                          child: Text(
                            '＋',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE30613),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add-on: Caramel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Caramel',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCaramelChecked = !_isCaramelChecked;
                          if (globalCart != null) _updateGlobalCart();
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE30613), width: 2),
                          color: _isCaramelChecked ? const Color(0xFFE30613) : Colors.transparent,
                        ),
                        child: _isCaramelChecked
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Total & Tombol Tambah ke Keranjang
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total :', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                    Text(
                      widget.price,
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Cari bagian ElevatedButton.icon di dalam file DetailPesananPage kamu:
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      // 1. Set kuantitas menjadi 1 (atau tambah +1) saat tombol ditekan
                      if (globalCartQuantity.value == 0) {
                        globalCartQuantity.value = 1;
                      }
                      
                      // 2. Perbarui data di dalam globalCart
                      _updateGlobalCart();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE30613),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Tambah ke Keranjang',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: globalCartQuantity,
        builder: (context, quantity, child) {
          // Jika kuantitas lebih dari 0 dan globalCart tidak null, tampilkan keranjang.
          // Jika 0, sembunyikan dengan mengembalikan SizedBox kosong.
          return (quantity > 0 && globalCart != null)
              ? globalCart!
              : const SizedBox.shrink();
        },
      ),
    );
  }

  void _updateGlobalCart() {
    globalCart = CartSummaryBar(
      name: widget.name,
      price: widget.price,
      imagePath: widget.imagePath,
      sugar: _selectedSugar,
      ice: _selectedIce,
      addOns: [
        if (_isBiscoffChecked) 'Biskuit Biscoff',
        if (_isCaramelChecked) 'Caramel',
        if (_espressoShots > 0) '$_espressoShots Espresso Shots',
      ],
    );
  }
}