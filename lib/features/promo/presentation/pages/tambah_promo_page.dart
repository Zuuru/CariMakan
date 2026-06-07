import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../data/promo_model.dart';
import '../../data/promo_service.dart';

/// Halaman form untuk membuat promo baru atau mengedit promo yang sudah ada.
///
/// Jika [existingPromo] diisi, halaman ini berfungsi sebagai mode edit
/// dan semua field akan di-prefill dengan data promo tersebut.
class TambahPromoPage extends StatefulWidget {
  final String restoId;
  final PromoModel? existingPromo;

  const TambahPromoPage({
    super.key,
    required this.restoId,
    this.existingPromo,
  });

  @override
  State<TambahPromoPage> createState() => _TambahPromoPageState();
}

class _TambahPromoPageState extends State<TambahPromoPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kodeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _nilaiDiskonController = TextEditingController();
  final _maksDiskonController = TextEditingController();
  final _minBelanjaController = TextEditingController();
  final _minItemController = TextEditingController();

  bool _isPercent = true;
  DateTime? _mulai;
  DateTime? _berakhir;
  bool _isLoading = false;
  File? _imageFile;

  bool get _isEditMode => widget.existingPromo != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final p = widget.existingPromo!;
      _namaController.text = p.nama;
      _deskripsiController.text = p.deskripsi;
      _kodeController.text = p.kode ?? '';
      _imageUrlController.text = p.imageUrl ?? '';
      _nilaiDiskonController.text = p.nilaiDiskon.toString();
      _isPercent = p.isPercent;
      if (p.maksDiskon != null) _maksDiskonController.text = p.maksDiskon.toString();
      _minBelanjaController.text = p.minBelanja.toString();
      _minItemController.text = p.minItem.toString();
      _mulai = p.mulai;
      _berakhir = p.berakhir;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _kodeController.dispose();
    _imageUrlController.dispose();
    _nilaiDiskonController.dispose();
    _maksDiskonController.dispose();
    _minBelanjaController.dispose();
    _minItemController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_mulai ?? now) : (_berakhir ?? now.add(const Duration(days: 7))),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFB72B31),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _mulai = picked;
        } else {
          _berakhir = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mulai == null || _berakhir == null) {
      _showSnackBar('Tanggal mulai dan berakhir harus diisi.', const Color(0xFFE53935));
      return;
    }

    if (_berakhir!.isBefore(_mulai!)) {
      _showSnackBar('Tanggal berakhir harus setelah tanggal mulai.', const Color(0xFFE53935));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null;

      if (_imageFile != null) {
        // TODO: Nanti upload _imageFile ke Firebase Storage di sini
        // Karena Firebase Storage belum aktif, kita gunakan placeholder dummy.
        finalImageUrl = 'https://via.placeholder.com/600x400?text=Gambar+Dari+Galeri';
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final promo = PromoModel(
        id: _isEditMode ? widget.existingPromo!.id : '',
        createdBy: _isEditMode ? widget.existingPromo!.createdBy : uid,
        restoId: widget.restoId,
        userId: null,
        nama: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kode: _kodeController.text.trim().isNotEmpty
            ? _kodeController.text.trim().toUpperCase()
            : null,
        imageUrl: finalImageUrl,
        nilaiDiskon: int.tryParse(_nilaiDiskonController.text.trim()) ?? 0,
        isPercent: _isPercent,
        maksDiskon: _isPercent && _maksDiskonController.text.trim().isNotEmpty
            ? int.tryParse(_maksDiskonController.text.trim())
            : null,
        minBelanja: int.tryParse(_minBelanjaController.text.trim()) ?? 0,
        minItem: int.tryParse(_minItemController.text.trim()) ?? 0,
        mulai: _mulai!,
        berakhir: _berakhir!,
        isActive: _isEditMode ? widget.existingPromo!.isActive : true,
      );

      if (_isEditMode) {
        await PromoService.updatePromo(promo);
      } else {
        await PromoService.tambahPromo(promo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Promo berhasil diperbarui! ✏️' : 'Promo berhasil dibuat! 🎉',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Gagal: $e', const Color(0xFFE53935));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Promo' : 'Buat Promo Baru',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB72B31).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditMode ? Icons.edit_outlined : Icons.discount_outlined,
                    size: 64,
                    color: const Color(0xFFB72B31),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _isEditMode ? 'Perbarui detail promo' : 'Isi detail promo baru untuk resto Anda',
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 32),

              // ── Informasi Promo ──
              _buildSectionTitle('Informasi Promo'),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Nama Promo',
                controller: _namaController,
                icon: Icons.local_offer_outlined,
                hintText: 'Contoh: Promo Makan Siang',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama promo wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Deskripsi',
                controller: _deskripsiController,
                icon: Icons.description_outlined,
                hintText: 'Contoh: Hemat 20% untuk order di atas 50rb',
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Kode Promo (Opsional)',
                controller: _kodeController,
                icon: Icons.code,
                hintText: 'Contoh: MAKAN20',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              
              // TextField URL yang disembunyikan/dijadikan opsional jika butuh
              // _buildTextField(
              //   label: 'Link Gambar Promo (Sementara)',
              //   controller: _imageUrlController,
              //   icon: Icons.image_outlined,
              //   hintText: 'Contoh: https://unsplash.com/...',
              // ),

              const SizedBox(height: 28),

              // ── Jenis & Nilai Diskon ──
              _buildSectionTitle('Jenis & Nilai Diskon'),
              const SizedBox(height: 12),
              // Toggle Persen / Nominal
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Persen (%)', _isPercent, () {
                      setState(() => _isPercent = true);
                    }),
                    _buildToggleButton('Nominal (Rp)', !_isPercent, () {
                      setState(() => _isPercent = false);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: _isPercent ? 'Nilai Diskon (%)' : 'Nilai Diskon (Rp)',
                controller: _nilaiDiskonController,
                icon: _isPercent ? Icons.percent : Icons.payments_outlined,
                hintText: _isPercent ? 'Contoh: 20' : 'Contoh: 15000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nilai diskon wajib diisi' : null,
              ),
              if (_isPercent) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Batas Maks. Potongan / Rp (Opsional)',
                  controller: _maksDiskonController,
                  icon: Icons.vertical_align_top_outlined,
                  hintText: 'Contoh: 50000 (kosongkan jika tidak ada batas)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],

              const SizedBox(height: 28),

              // ── Syarat ──
              _buildSectionTitle('Syarat Penggunaan'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Min. Belanja (Rp)',
                      controller: _minBelanjaController,
                      icon: Icons.shopping_cart_outlined,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Min. Item',
                      controller: _minItemController,
                      icon: Icons.format_list_numbered,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Masa Berlaku ──
              _buildSectionTitle('Masa Berlaku'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateField('Tanggal Mulai', _mulai, () => _selectDate(isStart: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField('Tanggal Berakhir', _berakhir, () => _selectDate(isStart: false))),
                ],
              ),

              const SizedBox(height: 40),

              // ── Tombol Simpan ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB72B31),
                    disabledBackgroundColor: const Color(0xFFB72B31).withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Buat Promo',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1C1C1C),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrlController.clear(); // Hapus URL teks jika sudah pilih gambar
      });
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gambar Promo (Opsional)',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : (_imageUrlController.text.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          _imageUrlController.text,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: Color(0xFF9CA3AF)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk pilih gambar dari galeri',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      )),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB72B31) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  static const _months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  static String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _fmtDate(date) : 'Pilih tanggal',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: date != null ? const Color(0xFF1C1C1C) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.outfit(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFB72B31)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
