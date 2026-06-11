import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/promo_model.dart';
import '../../data/promo_service.dart';
import 'tambah_promo_page.dart';

class ManajemenPromoPage extends StatefulWidget {
  final bool isEmbedded;
  const ManajemenPromoPage({super.key, this.isEmbedded = false});

  @override
  State<ManajemenPromoPage> createState() => _ManajemenPromoPageState();
}

class _ManajemenPromoPageState extends State<ManajemenPromoPage> {
  String? _restoId;
  bool _isLoadingRestoId = true;

  @override
  void initState() {
    super.initState();
    _loadRestoId();
  }

  /// Cari resto_id milik owner yang sedang login
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
        if (mounted) setState(() => _isLoadingRestoId = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRestoId = false);
    }
  }

  /// Toggle aktif/nonaktif promo
  Future<void> _toggleActive(PromoModel promo) async {
    final newState = !promo.isActive;
    final action = newState ? 'Aktifkan' : 'Nonaktifkan';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action Promo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          '$action promo "${promo.nama}"?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newState ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(action, style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PromoService.toggleActive(promo.id, newState);
      _showSnackBar(
        'Promo berhasil ${newState ? "diaktifkan" : "dinonaktifkan"}.',
        newState ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      );
    } catch (e) {
      _showSnackBar('Gagal: ${_cleanError(e)}', const Color(0xFFE53935));
    }
  }

  /// Hapus promo (hanya jika belum ada pemakaian)
  Future<void> _hapusPromo(PromoModel promo) async {
    // Cek pemakaian dulu
    final count = await PromoService.countPemakaian(promo.id);
    if (count > 0) {
      _showSnackBar(
        'Promo "${promo.nama}" sudah dipakai $count customer dan tidak bisa dihapus.',
        const Color(0xFFF59E0B),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Promo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(color: const Color(0xFF1C1C1C), fontSize: 14),
            children: [
              const TextSpan(text: 'Apakah Anda yakin ingin menghapus promo '),
              TextSpan(text: promo.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '?\n\n⚠️ Tindakan ini tidak bisa dikembalikan.'),
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
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PromoService.hapusPromo(promo.id);
      _showSnackBar('Promo "${promo.nama}" berhasil dihapus.', const Color(0xFF10B981));
    } catch (e) {
      _showSnackBar('Gagal: ${_cleanError(e)}', const Color(0xFFE53935));
    }
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

  String _cleanError(dynamic error) {
    String msg = error.toString();
    if (msg.startsWith('Exception: ')) msg = msg.replaceFirst('Exception: ', '');
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _isLoadingRestoId
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)))
          : _restoId == null
              ? _buildNoResto()
              : Container(
                  color: const Color(0xFFEFEFEF),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120), // space for bottom navigation bar
                    child: _buildPromoList(),
                  ),
                );
    }

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
          'Manajemen Promo',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ),
      body: _isLoadingRestoId
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB72B31)))
          : _restoId == null
              ? _buildNoResto()
              : _buildPromoList(),
      floatingActionButton: _restoId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TambahPromoPage(restoId: _restoId!),
                  ),
                );
              },
              backgroundColor: const Color(0xFFB72B31),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Buat Promo',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNoResto() {
    return Center(
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
    );
  }

  Widget _buildPromoList() {
    return StreamBuilder<List<PromoModel>>(
      stream: PromoService.getPromosByResto(_restoId!),
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

        final promos = snapshot.data ?? [];

        if (promos.isEmpty) {
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
                      Icons.discount_outlined,
                      size: 64,
                      color: Color(0xFFB72B31),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada promo',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klik tombol + Buat Promo untuk membuat promo pertama Anda.',
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
          itemCount: promos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildPromoCard(promos[index]);
          },
        );
      },
    );
  }

  Widget _buildPromoCard(PromoModel promo) {
    final statusLabel = promo.statusLabel;
    final statusColor = _getStatusColor(statusLabel);
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    String formatDate(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Gambar (jika ada)
          if (promo.imageUrl != null && promo.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                promo.imageUrl!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 140,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Header: Nama + Status + Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB72B31).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.discount_outlined,
                  color: Color(0xFFB72B31),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Nama + Kode
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.nama,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1C1C),
                      ),
                    ),
                    if (promo.kode != null && promo.kode!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promo.kode!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              // Popup Menu
              _buildPopupMenu(promo),
            ],
          ),
          const SizedBox(height: 12),
          // Diskon + Deskripsi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                Text(
                  promo.diskonLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    promo.deskripsi,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF9A3412),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Syarat + Masa Berlaku
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.calendar_today_outlined,
                  '${formatDate(promo.mulai)} - ${formatDate(promo.berakhir)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (promo.minBelanja > 0)
                Expanded(
                  child: _buildInfoChip(
                    Icons.shopping_cart_outlined,
                    'Min. Rp ${PromoModel.formatNumber(promo.minBelanja)}',
                  ),
                ),
              if (promo.minBelanja > 0 && promo.minItem > 0)
                const SizedBox(width: 8),
              if (promo.minItem > 0)
                Expanded(
                  child: _buildInfoChip(
                    Icons.format_list_numbered,
                    'Min. ${promo.minItem} item',
                  ),
                ),
            ],
          ),
          // Jumlah pemakaian (async)
          FutureBuilder<int>(
            future: PromoService.countPemakaian(promo.id),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildInfoChip(
                  Icons.people_outline,
                  '${snap.data} kali dipakai',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(PromoModel promo) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'edit') {
          final count = await PromoService.countPemakaian(promo.id);
          if (count > 0) {
            _showSnackBar(
              'Promo sudah dipakai $count customer dan tidak bisa diedit.',
              const Color(0xFFF59E0B),
            );
            return;
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TambahPromoPage(
                  restoId: _restoId!,
                  existingPromo: promo,
                ),
              ),
            );
          }
        } else if (value == 'toggle') {
          _toggleActive(promo);
        } else if (value == 'hapus') {
          _hapusPromo(promo);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: Color(0xFF1C1C1C), size: 20),
              const SizedBox(width: 8),
              Text('Edit', style: GoogleFonts.outfit()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                promo.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: const Color(0xFF1C1C1C),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                promo.isActive ? 'Nonaktifkan' : 'Aktifkan',
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
        ),
        PopupMenuItem(
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktif':
        return const Color(0xFF10B981);
      case 'Nonaktif':
        return const Color(0xFF6B7280);
      case 'Kadaluarsa':
        return const Color(0xFFE53935);
      case 'Belum Mulai':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
