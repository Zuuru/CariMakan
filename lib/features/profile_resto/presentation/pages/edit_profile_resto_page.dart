import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileRestoPage extends StatefulWidget {
  const EditProfileRestoPage({Key? key}) : super(key: key);

  @override
  State<EditProfileRestoPage> createState() => _EditProfileRestoPageState();
}

class _EditProfileRestoPageState extends State<EditProfileRestoPage> {
  final _namaRestController = TextEditingController(text: 'Gourmet Haven');
  final _deskripsiController = TextEditingController(text: 'Menyajikan hidangan terbaik dengan cita rasa otentik.');
  final _waRestController = TextEditingController(text: '081234567890');
  
  TimeOfDay _jamBuka = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamTutup = const TimeOfDay(hour: 22, minute: 0);

  final List<String> _fasilitasTersedia = ['WiFi', 'AC', 'Smoking Area', 'Parkir Luas', 'Mushola', 'Toilet', 'VIP Room'];
  final List<String> _fasilitasTerpilih = ['WiFi', 'AC', 'Parkir Luas'];

  @override
  void dispose() {
    _namaRestController.dispose();
    _deskripsiController.dispose();
    _waRestController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isBuka) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isBuka ? _jamBuka : _jamTutup,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFED001E), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isBuka) {
          _jamBuka = picked;
        } else {
          _jamTutup = picked;
        }
      });
    }
  }

  void _toggleFasilitas(String fasilitas) {
    setState(() {
      if (_fasilitasTerpilih.contains(fasilitas)) {
        _fasilitasTerpilih.remove(fasilitas);
      } else {
        _fasilitasTerpilih.add(fasilitas);
      }
    });
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
          'Edit Profil Resto',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto Resto Upload
            Center(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/background/bg_login.png'), // placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFED001E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField(
              label: 'Nama Resto',
              controller: _namaRestController,
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Deskripsi Singkat',
              controller: _deskripsiController,
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Nomor WhatsApp Resto',
              controller: _waRestController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 24),
            
            // Jam Buka & Tutup
            Text(
              'Jam Operasional',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    label: 'Buka',
                    time: _jamBuka,
                    onTap: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePicker(
                    label: 'Tutup',
                    time: _jamTutup,
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Badge Fasilitas
            Text(
              'Fasilitas Resto',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fasilitasTersedia.map((fasilitas) {
                final isSelected = _fasilitasTerpilih.contains(fasilitas);
                return FilterChip(
                  label: Text(
                    fasilitas,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleFasilitas(fasilitas),
                  selectedColor: const Color(0xFFED001E),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFED001E) : const Color(0xFFE5E7EB),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Lokasi GPS
            Text(
              'Lokasi (GPS)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFED001E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFFED001E)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Titik Lokasi Terpasang',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1C1C),
                          ),
                        ),
                        Text(
                          '-6.200000, 106.816666',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Mock update location
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lokasi GPS berhasil diperbarui!')),
                      );
                    },
                    child: Text(
                      'Update',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFED001E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save logic
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED001E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFF9CA3AF)) : null,
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
              borderSide: const BorderSide(color: Color(0xFFED001E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  time.format(context),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1C),
                  ),
                ),
              ],
            ),
            const Icon(Icons.access_time, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
