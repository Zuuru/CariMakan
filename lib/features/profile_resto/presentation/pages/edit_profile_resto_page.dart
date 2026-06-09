import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileRestoPage extends StatefulWidget {
  const EditProfileRestoPage({Key? key}) : super(key: key);

  @override
  State<EditProfileRestoPage> createState() => _EditProfileRestoPageState();
}

class _EditProfileRestoPageState extends State<EditProfileRestoPage> {
  final _namaRestController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _waRestController = TextEditingController();
  
  TimeOfDay _jamBuka = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamTutup = const TimeOfDay(hour: 22, minute: 0);

  final List<String> _fasilitasTersedia = ['WiFi', 'AC', 'Smoking Area', 'Parkir Luas', 'Mushola', 'Toilet', 'VIP Room'];
  final List<String> _fasilitasTerpilih = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _restoId;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadRestoData();
  }

  Future<void> _loadRestoData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        _restoId = doc.id;
        
        _namaRestController.text = data['nama'] ?? '';
        _deskripsiController.text = data['deskripsi'] ?? '';
        _waRestController.text = data['url_whatsapp'] ?? '';
        
        if (data['lokasi'] is GeoPoint) {
          final geo = data['lokasi'] as GeoPoint;
          _latitude = geo.latitude;
          _longitude = geo.longitude;
        }

        // Badges / Facilities
        final badges = data['badges'] as List<dynamic>?;
        if (badges != null) {
          _fasilitasTerpilih.clear();
          for (var item in badges) {
            if (_fasilitasTersedia.contains(item.toString())) {
              _fasilitasTerpilih.add(item.toString());
            }
          }
        }

        // Load operational hours from subcollection 'operational_hours'
        final opHoursSnapshot = await doc.reference.collection('operational_hours').get();
        if (opHoursSnapshot.docs.isNotEmpty) {
          final opDoc = opHoursSnapshot.docs.first;
          final opData = opDoc.data();
          final openTimeStr = opData['openTime'] as String?;
          final closeTimeStr = opData['closeTime'] as String?;
          
          if (openTimeStr != null && openTimeStr.contains(':')) {
            final parts = openTimeStr.split(':');
            _jamBuka = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          if (closeTimeStr != null && closeTimeStr.contains(':')) {
            final parts = closeTimeStr.split(':');
            _jamTutup = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil resto: $e')),
        );
      }
    }
  }

  Future<void> _saveRestoData() async {
    if (_restoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID restoran tidak ditemukan!')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('restaurants').doc(_restoId);
      
      // Update restaurant doc
      await docRef.update({
        'nama': _namaRestController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'url_whatsapp': _waRestController.text.trim(),
        'badges': _fasilitasTerpilih,
      });

      // Update operational hours for all days in the subcollection
      final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final openTimeStr = '${_jamBuka.hour.toString().padLeft(2, '0')}:${_jamBuka.minute.toString().padLeft(2, '0')}';
      final closeTimeStr = '${_jamTutup.hour.toString().padLeft(2, '0')}:${_jamTutup.minute.toString().padLeft(2, '0')}';

      final batch = FirebaseFirestore.instance.batch();
      for (var day in days) {
        final dayRef = docRef.collection('operational_hours').doc(day);
        batch.set(dayRef, {
          'day': day,
          'isOpen': true,
          'openTime': openTimeStr,
          'closeTime': closeTimeStr,
        }, SetOptions(merge: true));
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil restoran berhasil disimpan! 🎉', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    }
  }

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFED001E)),
            )
          : SingleChildScrollView(
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
                          _latitude != null && _longitude != null
                              ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                              : '-6.200000, 106.816666',
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
                onPressed: _isSaving ? null : _saveRestoData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED001E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
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
