import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import '../../../pesanan/presentation/pages/pembayaran_page.dart';
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

  const DetailMenuPage({
    Key? key,
    required this.restoId,
    required this.menuId,
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
  bool _isLoading = true;
  List<OptionGroupModel> _optionGroups = [];
  Map<String, Set<OptionItemModel>> _selectedOptions = {};
  bool _isAddedToCart = false;

  @override
  void initState() {
    super.initState();
    _fetchVariants();
  }

  Future<void> _fetchVariants() async {
    try {
      final groups = await MenuService.loadOptionGroupsWithItems(widget.menuId);
      if (mounted) {
        setState(() {
          _optionGroups = groups;
          // Initialize default selections
          for (var group in groups) {
            _selectedOptions[group.id] = {};
            if (group.wajib && group.tipe == 'single' && group.items.isNotEmpty) {
              _selectedOptions[group.id]!.add(group.items.first);
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
            backgroundColor: const Color(0xFFE30613),
          ),
        );
        return;
      }
    }
    setState(() {
      _isAddedToCart = true;
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
                      // Detail Container
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
                              topLeft: Radius.circular(16),
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

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Color(0xFFE30613)),
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
                        onPressed: _onAddToCart,
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
                  const SizedBox(height: 80), // give space for floating cart
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
                  // Format selected variants for the next page
                  Map<String, List<Map<String, dynamic>>> finalVariants = {};
                  _selectedOptions.forEach((groupId, items) {
                    final group = _optionGroups.firstWhere((g) => g.id == groupId);
                    finalVariants[group.nama] = items.map<Map<String, dynamic>>((item) => {
                      'nama': item.nama,
                      'hargaTambah': item.hargaTambah,
                    }).toList();
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PembayaranPage(
                        menuName: widget.menuName,
                        menuImage: widget.menuImage,
                        menuPrice: widget.menuPrice,
                        totalPrice: _totalPrice,
                        selectedVariants: finalVariants,
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
                  color: const Color(0xFFE30613).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Wajib',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFE30613),
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
                    border: Border.all(color: isSelected ? const Color(0xFFE30613) : Colors.grey),
                  ),
                  child: isSelected
                      ? const Center(child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFE30613)))
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
