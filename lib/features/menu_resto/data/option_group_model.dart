import 'package:cloud_firestore/cloud_firestore.dart';
import 'option_item_model.dart';

/// Model data untuk sub-collection `option_groups` di bawah dokumen menu.
///
/// Setiap grup merepresentasikan satu kelompok kustomisasi (misalnya:
/// "Tingkat Kepedasan", "Topping", dll.).
class OptionGroupModel {
  final String id;
  final String menuId;
  final String nama;
  final String tipe; // 'single' atau 'multiple'
  final bool wajib;
  final int urutan;

  /// Daftar item pilihan dalam grup ini.
  /// Di-load terpisah dari sub-collection `option_items`.
  List<OptionItemModel> items;

  OptionGroupModel({
    required this.id,
    required this.menuId,
    required this.nama,
    required this.tipe,
    this.wajib = false,
    this.urutan = 0,
    List<OptionItemModel>? items,
  }) : items = items ?? [];

  /// Label tipe yang user-friendly untuk ditampilkan di UI.
  String get tipeLabel => tipe == 'single' ? 'Pilih 1' : 'Pilih Banyak';

  /// Label wajib/opsional untuk ditampilkan di UI.
  String get wajibLabel => wajib ? 'Wajib' : 'Opsional';

  /// Factory constructor dari dokumen Firestore.
  factory OptionGroupModel.fromFirestore(DocumentSnapshot doc, {String menuId = ''}) {
    final data = doc.data() as Map<String, dynamic>;
    return OptionGroupModel(
      id: doc.id,
      menuId: menuId,
      nama: data['nama'] ?? '',
      tipe: data['tipe'] ?? 'single',
      wajib: data['wajib'] ?? false,
      urutan: data['urutan'] ?? 0,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'tipe': tipe,
      'wajib': wajib,
      'urutan': urutan,
    };
  }

  /// Copy with helper untuk update data.
  OptionGroupModel copyWith({
    String? id,
    String? menuId,
    String? nama,
    String? tipe,
    bool? wajib,
    int? urutan,
    List<OptionItemModel>? items,
  }) {
    return OptionGroupModel(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
      wajib: wajib ?? this.wajib,
      urutan: urutan ?? this.urutan,
      items: items ?? this.items,
    );
  }
}
