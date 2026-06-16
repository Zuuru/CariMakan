import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk dokumen di koleksi `menus` Firestore.
///
/// Setiap dokumen merepresentasikan satu item menu milik sebuah resto.
/// Variant/kustomisasi disimpan di sub-collection terpisah.
class MenuModel {
  final String id;
  final String restoId;
  final String nama;
  final int _hargaAsli;
  final String kategori;
  final String deskripsi;
  final String? imageUrl;
  final bool isAvailable;
  final int urutan;
  final DateTime? createdAt;

  MenuModel({
    required this.id,
    required this.restoId,
    required this.nama,
    required int harga,
    this.kategori = 'Makanan',
    this.deskripsi = '',
    this.imageUrl,
    this.isAvailable = true,
    this.urutan = 0,
    this.createdAt,
  }) : _hargaAsli = harga;

  /// Harga yang sudah di-markup 10% untuk ditampilkan ke customer
  int get harga => (_hargaAsli * 1.10).round();
  
  /// Harga asli dari restoran
  int get hargaAsli => _hargaAsli;

  /// Factory constructor dari dokumen Firestore.
  factory MenuModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuModel(
      id: doc.id,
      restoId: data['resto_id'] ?? '',
      nama: data['nama'] ?? '',
      harga: data['harga'] ?? 0,
      kategori: data['kategori'] ?? 'Makanan',
      deskripsi: data['deskripsi'] ?? '',
      imageUrl: data['image_url'],
      isAvailable: data['is_available'] ?? true,
      urutan: data['urutan'] ?? 0,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'resto_id': restoId,
      'nama': nama,
      'harga': _hargaAsli,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'urutan': urutan,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Format harga ke Rupiah (contoh: 10000 → "Rp 10.000")
  String get hargaFormatted => 'Rp ${formatNumber(harga)}';

  /// Format angka ribuan (contoh: 50000 → "50.000")
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Copy with helper untuk update data.
  MenuModel copyWith({
    String? id,
    String? restoId,
    String? nama,
    int? harga,
    String? kategori,
    String? deskripsi,
    String? imageUrl,
    bool? isAvailable,
    int? urutan,
    DateTime? createdAt,
  }) {
    return MenuModel(
      id: id ?? this.id,
      restoId: restoId ?? this.restoId,
      nama: nama ?? this.nama,
      harga: harga ?? this._hargaAsli,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      urutan: urutan ?? this.urutan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
