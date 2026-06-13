import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../data/menu_model.dart';
import '../../data/menu_service.dart';
import '../../data/option_group_model.dart';
import '../../data/option_item_model.dart';
import '../../data/variant_template_model.dart';

class TambahMenuPage extends StatefulWidget {
  final String restoId;
  final MenuModel? existingMenu;

  const TambahMenuPage({
    Key? key,
    required this.restoId,
    this.existingMenu,
  }) : super(key: key);

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
  bool _isLoading = false;

  // Variant state
  List<OptionGroupModel> _optionGroups = [];
  bool _isLoadingVariants = false;

  // Preset high fidelity Unsplash food images (sementara)
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
    final menu = widget.existingMenu;
    _nameController = TextEditingController(text: menu?.nama ?? '');
    _priceController = TextEditingController(
      text: menu != null ? menu.harga.toString() : '',
    );
    _descController = TextEditingController(text: menu?.deskripsi ?? '');
    _selectedCategory = menu?.kategori ?? 'Makanan';
    _isAvailable = menu?.isAvailable ?? true;
    _selectedImageUrl = menu?.imageUrl;

    if (menu != null) {
      _loadExistingVariants(menu.id);
    }
  }

  Future<void> _loadExistingVariants(String menuId) async {
    setState(() => _isLoadingVariants = true);
    try {
      final groups = await MenuService.loadOptionGroupsWithItems(menuId);
      if (mounted) {
        setState(() {
          _optionGroups = groups;
          _isLoadingVariants = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVariants = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // UI HANDLERS
  // ════════════════════════════════════════════════════════════════

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
                                ? const Color(0xFFD33400)
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
                                  color: Colors.black.withValues(alpha: 0.3),
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

  void _showAddVariantBottomSheet() {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                'Tambah Pilihan Kustomisasi',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Pilih dari Template
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showTemplateSelectionDialog();
                },
                icon: const Icon(Icons.style_rounded, color: Colors.white),
                label: Text(
                  'Pilih dari Template',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD33400),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Buat Sendiri
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCustomVariantForm();
                },
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFD33400)),
                label: Text(
                  'Buat Sendiri',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD33400),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFD33400), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showTemplateSelectionDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFD33400)),
      ),
    );

    try {
      final templates = await MenuService.getVariantTemplates();
      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (templates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template tidak tersedia. Gunakan "Buat Sendiri".')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          return _TemplateSelectionDialog(
            templates: templates,
            onTemplatesSelected: (selectedTemplates) {
              setState(() {
                for (final template in selectedTemplates) {
                  final newGroup = OptionGroupModel(
                    id: const Uuid().v4(), // generate temporary ID
                    menuId: '', // will be set on save
                    nama: template.nama,
                    tipe: template.tipe,
                    wajib: false, // default opsional
                    items: template.items.map((item) => OptionItemModel(
                      id: const Uuid().v4(),
                      groupId: '', // will be set on save
                      nama: item.nama,
                      hargaTambah: item.hargaTambah,
                    )).toList(),
                  );
                  _optionGroups.add(newGroup);
                }
              });
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCustomVariantForm([OptionGroupModel? group, int? index]) {
    showDialog(
      context: context,
      builder: (context) {
        return _VariantGroupFormDialog(
          initialGroup: group,
          onSave: (updatedGroup) {
            setState(() {
              if (index != null) {
                _optionGroups[index] = updatedGroup;
              } else {
                _optionGroups.add(updatedGroup);
              }
            });
          },
        );
      },
    );
  }

  void _removeVariantGroup(int index) {
    setState(() {
      _optionGroups.removeAt(index);
    });
  }

  // ════════════════════════════════════════════════════════════════
  // SAVE LOGIC
  // ════════════════════════════════════════════════════════════════

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final price = int.tryParse(_priceController.text) ?? 0;
      final description = _descController.text.trim();

      final menu = MenuModel(
        id: widget.existingMenu?.id ?? '', // kosong jika baru
        restoId: widget.restoId,
        nama: name,
        harga: price,
        isAvailable: _isAvailable,
        imageUrl: _selectedImageUrl,
        kategori: _selectedCategory,
        deskripsi: description,
        urutan: widget.existingMenu?.urutan ?? 0,
        createdAt: widget.existingMenu?.createdAt,
      );

      String menuId = menu.id;

      if (widget.existingMenu == null) {
        // Create baru
        menuId = await MenuService.tambahMenu(menu);
      } else {
        // Update existing
        await MenuService.updateMenu(menu);
      }

      // Handle variants update (simple approach for now: delete all existing, recreate new)
      // Note: for production with active orders, we'd want a more surgical update to avoid 
      // breaking existing order references, but since we use snapshot in order_items, 
      // it's relatively safe.
      
      if (widget.existingMenu != null) {
        // Hapus semua grup lama (untuk kemudahan sinkronisasi)
        final oldGroups = await MenuService.loadOptionGroupsWithItems(menuId);
        for (final g in oldGroups) {
          await MenuService.hapusOptionGroup(menuId, g.id);
        }
      }

      // Tulis ulang grup baru
      for (int i = 0; i < _optionGroups.length; i++) {
        final g = _optionGroups[i];
        final newGroup = g.copyWith(urutan: i);
        await MenuService.tambahOptionGroup(menuId, newGroup, newGroup.items);
      }

      if (mounted) {
        Navigator.pop(context, true); // true = success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan menu: $e'),
            backgroundColor: const Color(0xFFD33400),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMenu != null;

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
            color: const Color(0xFFD33400),
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
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      _buildBasicInfoFields(),
                      const SizedBox(height: 20),
                      _buildCategoryPicker(),
                      const SizedBox(height: 20),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      _buildAvailabilityToggle(),
                      const SizedBox(height: 32),
                      
                      // Kustomisasi Section
                      _buildVariantsSection(),
                      
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
                onPressed: _isLoading ? null : _onSavePressed,
                icon: _isLoading 
                    ? const SizedBox.shrink()
                    : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                label: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Simpan Menu',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD33400),
                  disabledBackgroundColor: const Color(0xFFD33400).withValues(alpha: 0.5),
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Menu',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A342B),
          ),
        ),
        const SizedBox(height: 8),
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
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
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
                              color: Color(0xFFD33400),
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
      ],
    );
  }

  Widget _buildBasicInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            if (int.tryParse(value) == null) {
              return 'Masukkan nominal angka yang valid';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFBEBEB) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD33400) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.outfit(
                    color: isSelected ? const Color(0xFFD33400) : const Color(0xFF555555),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
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
            activeColor: const Color(0xFFD33400),
            activeTrackColor: const Color(0xFFFBEBEB),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kustomisasi Pesanan',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (_isLoadingVariants)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Color(0xFFD33400), strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tambahkan pilihan kustomisasi seperti tingkat kepedasan, topping, dll.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // List of Option Groups
        if (_optionGroups.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _optionGroups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = _optionGroups[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.nama,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildBadge(group.wajibLabel, group.wajib ? const Color(0xFFD33400) : Colors.grey),
                                    const SizedBox(width: 8),
                                    _buildBadge(group.tipeLabel, Colors.blueGrey),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                            onPressed: () => _showCustomVariantForm(group, index),
                            splashRadius: 20,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFD33400), size: 20),
                            onPressed: () => _removeVariantGroup(index),
                            splashRadius: 20,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ),
                    // Items
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: group.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.nama,
                                    style: GoogleFonts.outfit(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  item.hargaLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: item.hargaTambah > 0 ? FontWeight.bold : FontWeight.normal,
                                    color: item.hargaTambah > 0 ? const Color(0xFF2E7D32) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Tambah Pilihan Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddVariantBottomSheet,
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFD33400)),
            label: Text(
              'Tambah Pilihan',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD33400),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFFBEBEB),
              side: const BorderSide(color: Color(0xFFD33400), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ════════════════════════════════════════════════════════════════

class _TemplateSelectionDialog extends StatefulWidget {
  final List<VariantTemplateModel> templates;
  final Function(List<VariantTemplateModel>) onTemplatesSelected;

  const _TemplateSelectionDialog({
    required this.templates,
    required this.onTemplatesSelected,
  });

  @override
  State<_TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<_TemplateSelectionDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Pilih Template', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.templates.length,
          itemBuilder: (context, index) {
            final template = widget.templates[index];
            final isSelected = _selectedIds.contains(template.id);
            return CheckboxListTile(
              title: Text(template.nama, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${template.items.length} pilihan (${template.tipe})',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
              value: isSelected,
              activeColor: const Color(0xFFD33400),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.add(template.id);
                  } else {
                    _selectedIds.remove(template.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  final selected = widget.templates
                      .where((t) => _selectedIds.contains(t.id))
                      .toList();
                  widget.onTemplatesSelected(selected);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD33400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Gunakan', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    );
  }
}

class _VariantGroupFormDialog extends StatefulWidget {
  final OptionGroupModel? initialGroup;
  final Function(OptionGroupModel) onSave;

  const _VariantGroupFormDialog({this.initialGroup, required this.onSave});

  @override
  State<_VariantGroupFormDialog> createState() => _VariantGroupFormDialogState();
}

class _VariantGroupFormDialogState extends State<_VariantGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _tipe;
  late bool _wajib;
  late List<OptionItemModel> _items;

  @override
  void initState() {
    super.initState();
    final g = widget.initialGroup;
    _nameController = TextEditingController(text: g?.nama ?? '');
    _tipe = g?.tipe ?? 'single';
    _wajib = g?.wajib ?? false;
    _items = g?.items.map((e) => e.copyWith()).toList() ?? [
      OptionItemModel(id: const Uuid().v4(), groupId: '', nama: '') // 1 empty item
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(OptionItemModel(id: const Uuid().v4(), groupId: '', nama: ''));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialGroup == null ? 'Buat Kustomisasi Baru' : 'Edit Kustomisasi',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Nama Grup
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      decoration: InputDecoration(
                        labelText: 'Nama Grup (cth: Tingkat Kepedasan)',
                        labelStyle: GoogleFonts.outfit(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipe Pilihan
                    Text('Tipe Pilihan', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Pilih 1', style: GoogleFonts.outfit(fontSize: 14)),
                            value: 'single',
                            groupValue: _tipe,
                            activeColor: const Color(0xFFD33400),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => _tipe = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Pilih Banyak', style: GoogleFonts.outfit(fontSize: 14)),
                            value: 'multiple',
                            groupValue: _tipe,
                            activeColor: const Color(0xFFD33400),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => _tipe = v!),
                          ),
                        ),
                      ],
                    ),

                    // Wajib Pilihan
                    SwitchListTile(
                      title: Text('Wajib Dipilih', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: Text('Pelanggan harus memilih sebelum order', style: GoogleFonts.outfit(fontSize: 12)),
                      value: _wajib,
                      activeColor: const Color(0xFFD33400),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _wajib = v),
                    ),
                    
                    const Divider(height: 32),
                    Text('Daftar Pilihan', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    // Items List
                    ...List.generate(_items.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            // Nama Item
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: _items[index].nama,
                                validator: (v) => v!.isEmpty ? 'Isi nama' : null,
                                onChanged: (v) => _items[index] = _items[index].copyWith(nama: v),
                                decoration: InputDecoration(
                                  hintText: 'Nama (cth: Pedas)',
                                  hintStyle: GoogleFonts.outfit(fontSize: 13),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Harga Item
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: _items[index].hargaTambah.toString(),
                                keyboardType: TextInputType.number,
                                validator: (v) => int.tryParse(v ?? '') == null ? 'Angka' : null,
                                onChanged: (v) => _items[index] = _items[index].copyWith(hargaTambah: int.tryParse(v) ?? 0),
                                decoration: InputDecoration(
                                  hintText: 'Harga (+)',
                                  hintStyle: GoogleFonts.outfit(fontSize: 13),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: _items.length > 1 ? () => _removeItem(index) : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Tambah Pilihan', style: GoogleFonts.outfit()),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFD33400)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newGroup = OptionGroupModel(
                          id: widget.initialGroup?.id ?? const Uuid().v4(),
                          menuId: widget.initialGroup?.menuId ?? '',
                          nama: _nameController.text.trim(),
                          tipe: _tipe,
                          wajib: _wajib,
                          items: _items,
                        );
                        widget.onSave(newGroup);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD33400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Simpan', style: GoogleFonts.outfit(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CUSTOM PAINTER
// ════════════════════════════════════════════════════════════════

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
