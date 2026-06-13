import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk koleksi `variant_templates` di Firestore.
///
/// Template variant bawaan sistem yang bisa dipilih oleh owner resto
/// saat menambahkan kustomisasi pesanan pada menu.
class VariantTemplateModel {
  final String id;
  final String nama;
  final String tipe; // 'single' atau 'multiple'
  final List<VariantTemplateItem> items;

  VariantTemplateModel({
    required this.id,
    required this.nama,
    required this.tipe,
    required this.items,
  });

  /// Factory constructor dari dokumen Firestore.
  factory VariantTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return VariantTemplateModel(
      id: doc.id,
      nama: data['nama'] ?? '',
      tipe: data['tipe'] ?? 'single',
      items: rawItems
          .map((item) => VariantTemplateItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'tipe': tipe,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  /// Data seed template bawaan sistem.
  /// Dipanggil sekali untuk mengisi koleksi `variant_templates`.
  static List<VariantTemplateModel> get seedData => [
        VariantTemplateModel(
          id: '',
          nama: 'Tingkat Kepedasan',
          tipe: 'single',
          items: [
            VariantTemplateItem(nama: 'Tidak Pedas', hargaTambah: 0),
            VariantTemplateItem(nama: 'Sedang', hargaTambah: 0),
            VariantTemplateItem(nama: 'Pedas', hargaTambah: 0),
            VariantTemplateItem(nama: 'Extra Pedas', hargaTambah: 0),
          ],
        ),
        VariantTemplateModel(
          id: '',
          nama: 'Topping',
          tipe: 'multiple',
          items: [
            VariantTemplateItem(nama: 'Keju', hargaTambah: 3000),
            VariantTemplateItem(nama: 'Telur', hargaTambah: 2000),
            VariantTemplateItem(nama: 'Sosis', hargaTambah: 5000),
            VariantTemplateItem(nama: 'Jamur', hargaTambah: 3000),
            VariantTemplateItem(nama: 'Bakso', hargaTambah: 4000),
          ],
        ),
        VariantTemplateModel(
          id: '',
          nama: 'Tingkat Gula',
          tipe: 'single',
          items: [
            VariantTemplateItem(nama: 'Normal', hargaTambah: 0),
            VariantTemplateItem(nama: 'Sedikit', hargaTambah: 0),
            VariantTemplateItem(nama: 'Tanpa Gula', hargaTambah: 0),
          ],
        ),
        VariantTemplateModel(
          id: '',
          nama: 'Tingkat Es',
          tipe: 'single',
          items: [
            VariantTemplateItem(nama: 'Normal', hargaTambah: 0),
            VariantTemplateItem(nama: 'Sedikit', hargaTambah: 0),
            VariantTemplateItem(nama: 'Tanpa Es', hargaTambah: 0),
          ],
        ),
      ];
}

/// Item individual dalam template variant.
class VariantTemplateItem {
  final String nama;
  final int hargaTambah;

  VariantTemplateItem({
    required this.nama,
    this.hargaTambah = 0,
  });

  factory VariantTemplateItem.fromMap(Map<String, dynamic> map) {
    return VariantTemplateItem(
      nama: map['nama'] ?? '',
      hargaTambah: map['harga_tambah'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'harga_tambah': hargaTambah,
    };
  }
}
