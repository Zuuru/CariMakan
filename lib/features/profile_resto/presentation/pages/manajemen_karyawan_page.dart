import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'tambah_karyawan_page.dart';
import '../../../manajemen_karyawan/data/karyawan_service.dart';

class ManajemenKaryawanPage extends StatefulWidget {
  const ManajemenKaryawanPage({Key? key}) : super(key: key);

  @override
  State<ManajemenKaryawanPage> createState() => _ManajemenKaryawanPageState();
}

class _ManajemenKaryawanPageState extends State<ManajemenKaryawanPage> {
  String? _restoId;
  bool _isLoadingRestoId = true;

  @override
  void initState() {
    super.initState();
    _loadRestoId();
  }

  /// Cari resto_id milik owner yang sedang login dari collection 'restaurants'
  Future<void> _loadRestoId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _restoId = snapshot.docs.first.id;
          _isLoadingRestoId = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoadingRestoId = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRestoId = false);
      }
    }
  }

  /// Toggle suspend/aktif via backend API
  Future<void> _toggleStatus(String uid, String nama, bool isCurrentlyActive) async {
    final action = isCurrentlyActive ? 'Suspend' : 'Aktifkan';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$action Karyawan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isCurrentlyActive
              ? 'Apakah Anda yakin ingin men-suspend $nama? Karyawan tidak akan bisa login.'
              : 'Apakah Anda yakin ingin mengaktifkan kembali $nama?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
<<<<<<< HEAD
            onPressed: () {
              setState(() {
                _listKaryawan.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED001E)),
=======
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(action, style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      _showLoadingDialog();
      await KaryawanService.toggleSuspendKaryawan(uid);
      if (mounted) Navigator.pop(context); // dismiss loading

      _showSnackBar(
        isCurrentlyActive
            ? '$nama berhasil di-suspend.'
            : '$nama berhasil diaktifkan kembali.',
        isCurrentlyActive ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss loading
      _showSnackBar('Gagal: ${_cleanErrorMessage(e)}', const Color(0xFFE53935));
    }
  }

  /// Hapus karyawan via backend API
  Future<void> _hapusKaryawan(String uid, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Karyawan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(color: const Color(0xFF1C1C1C), fontSize: 14),
            children: [
              const TextSpan(text: 'Apakah Anda yakin ingin menghapus '),
              TextSpan(
                text: nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: ' dari daftar karyawan?\n\n⚠️ Tindakan ini tidak bisa dikembalikan. '
                    'Akun karyawan akan dihapus permanen dari sistem.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
>>>>>>> c3e6a1110c7aa267f7aa23879a4396f61248688d
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      _showLoadingDialog();
      await KaryawanService.hapusKaryawan(uid);
      if (mounted) Navigator.pop(context); // dismiss loading
      _showSnackBar('$nama berhasil dihapus.', const Color(0xFF10B981));
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss loading
      _showSnackBar('Gagal: ${_cleanErrorMessage(e)}', const Color(0xFFE53935));
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFB72B31)),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
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

  String _cleanErrorMessage(dynamic error) {
    String msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.replaceFirst('Exception: ', '');
    }
    return msg;
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
<<<<<<< HEAD
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
=======
      body: _isLoadingRestoId
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB72B31)))
          : _restoId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_outlined, size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 16),
                        Text(
                          'Anda belum memiliki restoran.',
                          style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildKaryawanList(),
      floatingActionButton: _restoId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TambahKaryawanPage(restoId: _restoId!),
                  ),
                );
              },
              backgroundColor: const Color(0xFFB72B31),
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: Text(
                'Tambah',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
>>>>>>> c3e6a1110c7aa267f7aa23879a4396f61248688d
    );
  }

  Widget _buildKaryawanList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'karyawan')
          .where('resto_id', isEqualTo: _restoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.outfit(color: const Color(0xFFE53935)),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB72B31)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB72B31).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Color(0xFFB72B31),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada karyawan',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klik tombol + Tambah untuk menambahkan karyawan baru.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildKaryawanCard(data);
          },
        );
      },
    );
  }

  Widget _buildKaryawanCard(Map<String, dynamic> data) {
    final uid = data['id'] ?? '';
    final nama = data['nama'] ?? 'Tanpa Nama';
    final email = data['email'] ?? '';
    final status = data['status'] ?? 'aktif';
    final fotoUrl = data['foto_url'];
    final isAktif = status == 'aktif';

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
              color: const Color(0xFFF3F4F6),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              image: fotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(fotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fotoUrl == null
                ? Center(
                    child: Text(
                      nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB72B31),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Info Karyawan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1C),
                  ),
                ),
                Text(
                  email,
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
                    color: isAktif
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAktif ? 'Aktif' : 'Suspended',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAktif ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
                _toggleStatus(uid, nama, isAktif);
              } else if (value == 'hapus') {
                _hapusKaryawan(uid, nama);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(
                      isAktif ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: const Color(0xFF1C1C1C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(isAktif ? 'Suspend' : 'Aktifkan', style: GoogleFonts.outfit()),
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
