import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tambah_karyawan_page.dart';

class KaryawanModel {
  final String nama;
  final String email;
  final String fotoPath;
  bool isAktif;

  KaryawanModel({
    required this.nama,
    required this.email,
    required this.fotoPath,
    this.isAktif = true,
  });
}

class ManajemenKaryawanPage extends StatefulWidget {
  const ManajemenKaryawanPage({Key? key}) : super(key: key);

  @override
  State<ManajemenKaryawanPage> createState() => _ManajemenKaryawanPageState();
}

class _ManajemenKaryawanPageState extends State<ManajemenKaryawanPage> {
  final List<KaryawanModel> _listKaryawan = [
    KaryawanModel(
      nama: 'Budi Santoso',
      email: 'budi.santoso@resto.com',
      fotoPath: 'assets/images/Icon/icon_carimakan.png',
    ),
    KaryawanModel(
      nama: 'Siti Aminah',
      email: 'siti.aminah@resto.com',
      fotoPath: 'assets/images/Icon/icon_carimakan.png',
      isAktif: false,
    ),
    KaryawanModel(
      nama: 'Andi Setiawan',
      email: 'andi.setiawan@resto.com',
      fotoPath: 'assets/images/Icon/icon_carimakan.png',
    ),
  ];

  void _toggleStatus(int index) {
    setState(() {
      _listKaryawan[index].isAktif = !_listKaryawan[index].isAktif;
    });
  }

  void _hapusKaryawan(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Karyawan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus ${_listKaryawan[index].nama} dari daftar karyawan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _listKaryawan.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED001E)),
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
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
          'Manajemen Karyawan',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _listKaryawan.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final karyawan = _listKaryawan[index];
          return _buildKaryawanCard(karyawan, index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahKaryawanPage()),
          );
        },
        backgroundColor: const Color(0xFFED001E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildKaryawanCard(KaryawanModel karyawan, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto Profil
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(karyawan.fotoPath),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
          ),
          const SizedBox(width: 16),
          // Info Karyawan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  karyawan.nama,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1C),
                  ),
                ),
                Text(
                  karyawan.email,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: karyawan.isAktif
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    karyawan.isAktif ? 'Aktif' : 'Suspended',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: karyawan.isAktif ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Aksi (Popup Menu)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'suspend') {
                _toggleStatus(index);
              } else if (value == 'hapus') {
                _hapusKaryawan(index);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(
                      karyawan.isAktif ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: const Color(0xFF1C1C1C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(karyawan.isAktif ? 'Suspend' : 'Aktifkan', style: GoogleFonts.outfit()),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'hapus',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20),
                    const SizedBox(width: 8),
                    Text('Hapus', style: GoogleFonts.outfit(color: const Color(0xFFE53935))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
