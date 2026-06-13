import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk sub-collection `option_items` di bawah option_groups.
///
/// Setiap item merepresentasikan satu pilihan dalam grup kustomisasi
/// (misalnya: "Pedas", "Keju", "Extra Es", dll.).
class OptionItemModel {
  final String id;
  final String groupId;
  final String nama;
  final int hargaTambah; // 0 = gratis, >0 = ada tambahan harga
  final int urutan;

  OptionItemModel({
    required this.id,
    required this.groupId,
    required this.nama,
    this.hargaTambah = 0,
    this.urutan = 0,
  });

  /// Label harga yang user-friendly untuk ditampilkan di UI.
  /// Contoh: "+ Rp 3.000" atau "Gratis"
  String get hargaLabel {
    if (hargaTambah <= 0) return 'Gratis';
    return '+ Rp ${_formatNumber(hargaTambah)}';
  }

  /// Factory constructor dari dokumen Firestore.
  factory OptionItemModel.fromFirestore(DocumentSnapshot doc, {String groupId = ''}) {
    final data = doc.data() as Map<String, dynamic>;
    return OptionItemModel(
      id: doc.id,
      groupId: groupId,
      nama: data['nama'] ?? '',
      hargaTambah: data['harga_tambah'] ?? 0,
      urutan: data['urutan'] ?? 0,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'harga_tambah': hargaTambah,
      'urutan': urutan,
    };
  }

  /// Copy with helper untuk update data.
  OptionItemModel copyWith({
    String? id,
    String? groupId,
    String? nama,
    int? hargaTambah,
    int? urutan,
  }) {
    return OptionItemModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      nama: nama ?? this.nama,
      hargaTambah: hargaTambah ?? this.hargaTambah,
      urutan: urutan ?? this.urutan,
    );
  }

  /// Format angka ribuan (contoh: 5000 → "5.000")
  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
