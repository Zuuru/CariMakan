import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk dokumen di koleksi `promo_voucher` Firestore.
///
/// Mapping 1:1 dengan struktur data yang didefinisikan di
/// docs/workflow_promo_voucher.md — Bagian 2. Struktur Data.
class PromoModel {
  final String id;
  final String createdBy;
  final String? restoId;
  final String? userId;

  final String nama;
  final String deskripsi;
  final String? kode;
  final String? imageUrl;

  final int nilaiDiskon;
  final bool isPercent;
  final int? maksDiskon;

  final int minBelanja;
  final int minItem;

  final DateTime mulai;
  final DateTime berakhir;

  final bool isActive;

  PromoModel({
    required this.id,
    required this.createdBy,
    this.restoId,
    this.userId,
    required this.nama,
    required this.deskripsi,
    this.kode,
    this.imageUrl,
    required this.nilaiDiskon,
    required this.isPercent,
    this.maksDiskon,
    required this.minBelanja,
    required this.minItem,
    required this.mulai,
    required this.berakhir,
    required this.isActive,
  });

  /// Cek apakah promo sudah melewati tanggal berakhir.
  bool get isExpired => DateTime.now().isAfter(berakhir);

  /// Cek apakah promo belum dimulai.
  bool get isUpcoming => DateTime.now().isBefore(mulai);

  /// Label status promo untuk ditampilkan di UI.
  String get statusLabel {
    if (!isActive) return 'Nonaktif';
    if (isExpired) return 'Kadaluarsa';
    if (isUpcoming) return 'Belum Mulai';
    return 'Aktif';
  }

  /// Label ringkasan diskon untuk ditampilkan di card.
  /// Contoh: "20%" atau "Rp 15.000"
  String get diskonLabel {
    if (isPercent) {
      final maxLabel = maksDiskon != null ? ' (maks Rp ${_formatNumber(maksDiskon!)})' : '';
      return '$nilaiDiskon%$maxLabel';
    }
    return 'Rp ${_formatNumber(nilaiDiskon)}';
  }

  /// Factory constructor dari dokumen Firestore.
  factory PromoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoModel(
      id: doc.id,
      createdBy: data['created_by'] ?? '',
      restoId: data['resto_id'],
      userId: data['user_id'],
      nama: data['nama'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      kode: data['kode'],
      imageUrl: data['image_url'],
      nilaiDiskon: data['nilai_diskon'] ?? 0,
      isPercent: data['is_percent'] ?? false,
      maksDiskon: data['maks_diskon'],
      minBelanja: data['min_belanja'] ?? 0,
      minItem: data['min_item'] ?? 0,
      mulai: (data['mulai'] as Timestamp).toDate(),
      berakhir: (data['berakhir'] as Timestamp).toDate(),
      isActive: data['is_active'] ?? true,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'created_by': createdBy,
      'resto_id': restoId,
      'user_id': userId,
      'nama': nama,
      'deskripsi': deskripsi,
      'kode': kode,
      'image_url': imageUrl,
      'nilai_diskon': nilaiDiskon,
      'is_percent': isPercent,
      'maks_diskon': maksDiskon,
      'min_belanja': minBelanja,
      'min_item': minItem,
      'mulai': Timestamp.fromDate(mulai),
      'berakhir': Timestamp.fromDate(berakhir),
      'is_active': isActive,
    };
  }

  /// Format angka ribuan (contoh: 50000 → "50.000")
  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Helper statis agar bisa dipanggil dari luar class.
  static String formatNumber(int number) => _formatNumber(number);
}
