import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import '../../../pesanan/presentation/pages/pembayaran_page.dart';
import '../../../pesanan/data/cart_service.dart';
import '../../../menu_resto/data/menu_service.dart';
import '../../../menu_resto/data/option_group_model.dart';
import '../../../menu_resto/data/option_item_model.dart';

class DetailMenuPage extends StatefulWidget {
  final String restoId;
  final String menuId;
  final String restoName;
  final String menuName;
  final String menuImage;
  final double menuPrice;
  final String description;
  
  final Map<String, List<Map<String, dynamic>>>? initialSelectedVariants;
  final int? initialQuantity;
  final int? cartIndex; // 💡 TAMBAHKAN PARAMETER INDEX INI UNTUK MENUNJUK DATA YANG MAU DIEDIT

  const DetailMenuPage({
    Key? key,
    required this.restoId,
    required this.menuId,
    required this.restoName,
    required this.menuName,
    required this.menuImage,
    required this.menuPrice,
    required this.description,
    this.initialSelectedVariants, // null jika tambah baru
    this.initialQuantity,          // null jika tambah baru
    this.cartIndex,               // 💡 null jika tambah baru, terisi angka index jika mode edit
  }) : super(key: key);

  @override
  State<DetailMenuPage> createState() => _DetailMenuPageState();
}

class _DetailMenuPageState extends State<DetailMenuPage> {
  bool _isLoading = true;
  List<OptionGroupModel> _optionGroups = [];
  Map<String, Set<OptionItemModel>> _selectedOptions = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity ?? 1;
    _fetchVariants();
  }

  Future<void> _fetchVariants() async {
    try {
      final groups = await MenuService.loadOptionGroupsWithItems(widget.menuId);
      if (mounted) {
        setState(() {
          _optionGroups = groups;
          
          // Initialize selections
          for (var group in groups) {
            _selectedOptions[group.id] = {};

            if (widget.initialSelectedVariants != null && 
                widget.initialSelectedVariants!.containsKey(group.nama)) {
              
              final savedItems = widget.initialSelectedVariants![group.nama] ?? [];
              
              // COCOKKAN item dari DB dengan nama item yang ada di keranjang
              for (var savedItem in savedItems) {
                for (var dbItem in group.items) {
                  if (dbItem.nama == savedItem['nama']) {
                    _selectedOptions[group.id]!.add(dbItem);
                  }
                }
              }
            } else {
              if (group.wajib && group.tipe == 'single' && group.items.isNotEmpty) {
                _selectedOptions[group.id]!.add(group.items.first);
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail menu: $e')),
        );
      }
    }
  }

  double get _totalPrice {
    double total = widget.menuPrice;
    for (var items in _selectedOptions.values) {
      for (var item in items) {
        total += item.hargaTambah;
      }
    }
    return total;
  }

  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  void _onAddToCart() {
    // Validasi opsi wajib
    for (var group in _optionGroups) {
      if (group.wajib && (_selectedOptions[group.id] == null || _selectedOptions[group.id]!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${group.nama} wajib dipilih!', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: const Color(0xFFD33400),
          ),
        );
        return;
      }
    }
    
    // Format selected variants
    Map<String, List<Map<String, dynamic>>> finalVariants = {};
    _selectedOptions.forEach((groupId, items) {
      final group = _optionGroups.firstWhere((g) => g.id == groupId);
      finalVariants[group.nama] = items.map<Map<String, dynamic>>((item) => {
        'nama': item.nama,
        'hargaTambah': item.hargaTambah,
      }).toList();
    });

    final cartItem = CartItemModel(
      menuId: widget.menuId,
      menuName: widget.menuName,
      menuImage: widget.menuImage,
      basePrice: widget.menuPrice,
      totalPrice: _totalPrice,
      quantity: _quantity,
      selectedVariants: finalVariants,
      description: widget.description,
    );

    // 💡 PERUBAHAN LOGIKA UTAMA DI SINI
    if (widget.cartIndex != null) {
      // 🔄 MODE EDIT: Panggil fungsi updateItem berdasarkan index-nya agar tidak menduplikasi pesanan baru
      CartService.instance.updateItem(widget.restoId, widget.cartIndex!, cartItem);
    } else {
      // ➕ MODE TAMBAH BARU: Jalankan penambahan menu baru seperti biasa
      CartService.instance.addItem(widget.restoId, cartItem);
    }
    
    Navigator.pop(context); // Go back to Resto Page
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.menuImage.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      height: 140,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                    )
                                  : widget.menuImage.startsWith('http')
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
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD33400),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
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

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Color(0xFFD33400)),
                      ),
                    )
                  else if (_optionGroups.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'Tidak ada kustomisasi untuk menu ini.',
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ..._optionGroups.map((group) => _buildOptionGroup(group)).toList(),

                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(Icons.remove, size: 16, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$_quantity',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFD33400),
                              ),
                              child: const Icon(Icons.add, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

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
                            _formatRupiah(_totalPrice * _quantity),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _onAddToCart,
                        icon: const Icon(Icons.add, color: Colors.white, size: 16),
                        label: Text(
                          widget.cartIndex != null ? 'Simpan Perubahan' : 'Tambah ke Keranjang',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD33400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroup(OptionGroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                group.nama,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            if (group.wajib)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD33400).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Wajib',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFD33400),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (group.tipe == 'single')
          _buildSingleChoiceRow(group)
        else
          _buildMultipleChoiceList(group),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSingleChoiceRow(OptionGroupModel group) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: group.items.map((item) {
          final isSelected = _selectedOptions[group.id]?.contains(item) ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildOptionCircle(
              item.nama,
              isSelected,
              () {
                setState(() {
                  _selectedOptions[group.id]!.clear();
                  _selectedOptions[group.id]!.add(item);
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultipleChoiceList(OptionGroupModel group) {
    return Column(
      children: group.items.map((item) {
        final isSelected = _selectedOptions[group.id]?.contains(item) ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nama, style: GoogleFonts.poppins(fontSize: 12)),
                    if (item.hargaTambah > 0)
                      Text(
                        '+ ${_formatRupiah(item.hargaTambah.toDouble())}',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedOptions[group.id]!.remove(item);
                    } else {
                      _selectedOptions[group.id]!.add(item);
                    }
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? const Color(0xFFD33400) : Colors.grey),
                  ),
                  child: isSelected
                      ? const Center(child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFD33400)))
                      : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
                color: isSelected ? const Color(0xFFD33400) : Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Center(
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFFD33400),
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