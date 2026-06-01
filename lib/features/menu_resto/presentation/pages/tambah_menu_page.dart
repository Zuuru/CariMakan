import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manajemen_menu_page.dart';

class TambahMenuPage extends StatefulWidget {
  final ItemMenu? menu;

  const TambahMenuPage({Key? key, this.menu}) : super(key: key);

  @override
  State<TambahMenuPage> createState() => _TambahMenuPageState();
}

class _TambahMenuPageState extends State<TambahMenuPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  
  String _selectedCategory = 'Makanan';
  bool _isAvailable = true;
  String? _selectedImageUrl;

  // Preset high fidelity Unsplash food images
  final List<Map<String, String>> _presets = [
    {
      'name': 'Mie Ayam',
      'url': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
    },
    {
      'name': 'Mie Pangsit',
      'url': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
    },
    {
      'name': 'Nasi Goreng',
      'url': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500',
    },
    {
      'name': 'Es Teh Manis',
      'url': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
    },
    {
      'name': 'Ayam Goreng',
      'url': 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=500',
    },
    {
      'name': 'Sate Ayam',
      'url': 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=500',
    },
  ];

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _nameController = TextEditingController(text: menu?.title ?? '');
    _priceController = TextEditingController(
      text: menu != null ? menu.price.toInt().toString() : '',
    );
    _descController = TextEditingController(text: menu?.description ?? '');
    _selectedCategory = menu?.category ?? 'Makanan';
    _isAvailable = menu?.isAvailable ?? true;
    _selectedImageUrl = menu?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showPresetBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pilih Foto Menu',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih salah satu preset makanan resolusi tinggi di bawah ini:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final item = _presets[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageUrl = item['url'];
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedImageUrl == item['url']
                                ? const Color(0xFFB72B31)
                                : Colors.grey[200]!,
                            width: _selectedImageUrl == item['url'] ? 2.5 : 1.5,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(item['url']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: _selectedImageUrl == item['url']
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _onSavePressed() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final description = _descController.text.trim();

      final resultMenu = ItemMenu(
        id: widget.menu?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: name,
        price: price,
        isAvailable: _isAvailable,
        imageUrl: _selectedImageUrl,
        category: _selectedCategory,
        description: description,
      );

      Navigator.pop(context, resultMenu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menu != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.all(4),
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
        title: Text(
          isEditing ? 'Edit Menu' : 'Tambah Menu Baru',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB72B31),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto Menu Label
                      Text(
                        'Foto Menu',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A342B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Custom Dashed Image Upload Box
                      GestureDetector(
                        onTap: _showPresetBottomSheet,
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: const Color(0xFFE5CFC8),
                            radius: 16,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              color: Colors.transparent,
                              child: _selectedImageUrl != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          _selectedImageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          color: Colors.black.withOpacity(0.15),
                                        ),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Ganti Foto',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFBEBEB),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo_outlined,
                                            color: Color(0xFFB72B31),
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Tap untuk upload foto',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF8E7E78),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nama Menu Field
                      Text(
                        'Nama Menu',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A342B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.outfit(fontSize: 15),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama menu tidak boleh kosong';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Contoh: Nasi Goreng Spesial',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFFADADAD),
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Harga Field
                      Text(
                        'Harga',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A342B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(fontSize: 15),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Masukkan nominal angka yang valid';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Color(0xFFE5E5E5),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Text(
                              'Rp',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A342B),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: '0',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFFADADAD),
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Kategori Field
                      Text(
                        'Kategori',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A342B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Makanan', 'Minuman', 'Snack', 'Paket'].map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFBEBEB)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFB72B31)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.outfit(
                                  color: isSelected
                                      ? const Color(0xFFB72B31)
                                      : const Color(0xFF555555),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Deskripsi Field
                      Text(
                        'Deskripsi',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A342B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: GoogleFonts.outfit(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Jelaskan detail menu ini...',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFFADADAD),
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Ketersediaan Container Switch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Menu Langsung Tersedia',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Aktifkan agar pelanggan bisa langsung memesan',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF8E8E93),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isAvailable,
                              onChanged: (value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                              activeColor: const Color(0xFFB72B31),
                              activeTrackColor: const Color(0xFFFBEBEB),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            // Persistent Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: ElevatedButton.icon(
                onPressed: _onSavePressed,
                icon: const Icon(
                  Icons.save_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  'Simpan Menu',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB72B31),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw beautiful Dashed Borders
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.dashLength = 7.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = Path();
    double distance = 0.0;
    for (PathMetric measure in path.computeMetrics()) {
      while (distance < measure.length) {
        dashPath.addPath(
          measure.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.radius != radius;
  }
}
