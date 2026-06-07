# Workflow: Sistem Variant Menu — cariMakan

Dokumen ini menjelaskan alur kerja, struktur data, dan logika implementasi
untuk fitur kustomisasi pesanan (variant & add-on) di aplikasi cariMakan.

---

## 1. Gambaran Umum

Sistem variant memungkinkan Owner Resto untuk menambahkan pilihan kustomisasi
pada setiap menu mereka. Customer dapat memilih kustomisasi tersebut saat
melakukan order.

Ada dua cara owner membuat variant:

| Cara | Keterangan |
|---|---|
| Template bawaan | Pilih dari daftar template yang sudah disediakan sistem |
| Custom dari nol | Buat grup pilihan sendiri sesuai kebutuhan resto |

---

## 2. Konsep Dasar

### Dua Jenis Tipe Pilihan:

```
SINGLE (pilih salah satu — seperti radio button)
  Contoh: Tingkat Kepedasan
  → Tidak Pedas  ATAU  Sedang  ATAU  Pedas  ATAU  Extra Pedas
  → Customer hanya boleh pilih 1

MULTIPLE (pilih banyak — seperti checkbox)
  Contoh: Topping
  → Keju  DAN/ATAU  Telur  DAN/ATAU  Sosis
  → Customer boleh pilih 0 atau lebih
```

### Dua Jenis Harga Pilihan:

```
Gratis       → harga_tambah: 0
Berbayar     → harga_tambah: 3000 (ditambahkan ke harga menu dasar)
```

---

## 3. Struktur Data

### 3.1 Tabel Master Template (dikelola sistem/admin)

```
VARIANT_TEMPLATE {
  id      string   PK
  nama    string   "Tingkat Kepedasan" | "Topping" | "Gula" | "Es"
  tipe    string   "single" | "multiple"
}

VARIANT_TEMPLATE_ITEM {
  id           string   PK
  template_id  string   FK → VARIANT_TEMPLATE
  nama         string   "Tidak Pedas" | "Pedas" | "Keju" | dll
}
```

Contoh isi template bawaan:

| Template | Tipe | Item |
|---|---|---|
| Tingkat Kepedasan | single | Tidak Pedas, Sedang, Pedas, Extra Pedas |
| Topping | multiple | Keju, Telur, Sosis, Jamur, Bakso |
| Tingkat Gula | single | Normal, Sedikit, Tanpa Gula |
| Tingkat Es | single | Normal, Sedikit, Tanpa Es |

---

### 3.2 Tabel Variant per Menu (dibuat oleh owner)

```
MENU_OPTION_GROUP {
  id        string   PK
  menu_id   string   FK → MENU
  nama      string   "Tingkat Kepedasan" (bisa rename dari template)
  tipe      string   "single" | "multiple"
  wajib     bool     true = customer wajib pilih
                     false = opsional
  urutan    int      urutan tampil di UI (1, 2, 3, ...)
}

MENU_OPTION_ITEM {
  id            string   PK
  group_id      string   FK → MENU_OPTION_GROUP
  nama          string   "Pedas"
  harga_tambah  int      0 = gratis | >0 = ada tambahan harga
  urutan        int      urutan tampil dalam grup
}
```

---

### 3.3 Tabel Pilihan Customer saat Order

```
ORDER_ITEM_OPTION {
  id              string   PK
  order_item_id   string   FK → ORDER_ITEM
  option_item_id  string   FK → MENU_OPTION_ITEM
  nama_snapshot   string   nama pilihan saat order (antisipasi perubahan)
  harga_snapshot  int      harga tambah saat order (antisipasi perubahan)
}
```

> Kenapa pakai snapshot?
> Kalau owner ubah nama/harga pilihan setelah ada yang order,
> riwayat order lama tetap akurat karena sudah disimpan nilainya.

---

## 4. Alur Lengkap

### 4.1 Owner Tambah Variant ke Menu

```
[Flutter — Owner]
Owner buka form tambah / edit menu
      ↓
Scroll ke section "Kustomisasi Pesanan"
      ↓
Klik [+ Tambah Pilihan]
      ↓
Muncul bottom sheet pilihan cara buat:

  ┌────────────────────────────────────┐
  │  Tambah Pilihan Kustomisasi        │
  │                                    │
  │  [Pilih dari Template]             │
  │  Kepedasan, Topping, Gula, Es      │
  │                                    │
  │  [Buat Sendiri]                    │
  │  Buat pilihan kustom dari nol      │
  └────────────────────────────────────┘

─── Pilih dari Template ─────────────────────────────

Owner pilih template yang diinginkan:
  ☑ Tingkat Kepedasan
  ☑ Topping
  ☐ Tingkat Gula
  ☐ Tingkat Es
      ↓
Klik [Gunakan Template]
      ↓
Grup pilihan muncul di form, sudah terisi item default
Owner bisa langsung edit:
  • Rename nama grup
  • Tambah item baru
  • Hapus item yang tidak relevan
  • Set harga tambah tiap item
  • Set wajib / tidak wajib

─── Buat Sendiri ────────────────────────────────────

Owner isi dari kosong:
  Nama grup   : [Pilihan Nasi      ]
  Tipe        : ● Pilih 1  ○ Pilih Banyak
  Wajib       : ● Ya  ○ Tidak

  Item pilihan:
  ┌─────────────────────┬──────────────┐
  │ Nasi Putih          │ + Rp 0       │ [x]
  │ Nasi Merah          │ + Rp 2.000   │ [x]
  │ Tanpa Nasi          │ + Rp 0       │ [x]
  └─────────────────────┴──────────────┘
  [+ Tambah Item]
      ↓
Klik [Simpan Grup]
      ↓
Grup muncul di section kustomisasi form menu
```

---

### 4.2 Owner Kelola Variant yang Sudah Ada

```
Di form edit menu, section kustomisasi:

┌─────────────────────────────────────────┐
│ Tingkat Kepedasan  (wajib · pilih 1)   [Edit] [Hapus]
│   • Tidak Pedas    + Rp 0              │
│   • Sedang         + Rp 0              │
│   • Pedas          + Rp 0              │
│   • Extra Pedas    + Rp 0              │
├─────────────────────────────────────────┤
│ Topping  (opsional · pilih banyak)     [Edit] [Hapus]
│   • Keju           + Rp 3.000          │
│   • Telur          + Rp 2.000          │
│   • Sosis          + Rp 5.000          │
└─────────────────────────────────────────┘
[+ Tambah Pilihan]

Owner bisa:
  • Edit grup → ubah nama, tipe, wajib, item-item di dalamnya
  • Hapus grup → semua item dalam grup ikut terhapus
  • Reorder grup → drag untuk ubah urutan tampil
```

---

### 4.3 Customer Pilih Variant saat Order

```
[Flutter — Customer]
Customer browse menu → klik item menu
      ↓
Muncul bottom sheet detail menu:

  ┌────────────────────────────────────────┐
  │ Nasi Goreng Spesial                    │
  │ Rp 25.000                              │
  │ Nasi goreng dengan bumbu rahasia...    │
  │                                        │
  │ ── Tingkat Kepedasan * (wajib) ──────  │
  │ ○ Tidak Pedas         + Rp 0           │
  │ ● Sedang              + Rp 0  ←dipilih │
  │ ○ Pedas               + Rp 0           │
  │ ○ Extra Pedas         + Rp 0           │
  │                                        │
  │ ── Topping (opsional) ───────────────  │
  │ ☑ Keju                + Rp 3.000       │
  │ ☐ Telur               + Rp 2.000       │
  │ ☑ Sosis               + Rp 5.000       │
  │ ☐ Jamur               + Rp 3.000       │
  │                                        │
  │ ─────────────────────────────────────  │
  │ Subtotal:  Rp 25.000 + 3.000 + 5.000   │
  │            = Rp 33.000                 │
  │                                        │
  │         [-]  1  [+]                    │
  │   [Tambah ke Keranjang — Rp 33.000]    │
  └────────────────────────────────────────┘

Validasi sebelum tambah ke keranjang:
  → Cek semua grup yang wajib sudah dipilih
  → Jika ada yang belum:
     highlight border merah pada grup tersebut
     tampilkan: "Pilih tingkat kepedasan terlebih dahulu"
  → Semua lolos → masuk keranjang
```

---

### 4.4 Menyimpan Pilihan ke Order

```
Saat customer checkout dan order berhasil dibuat:

Untuk setiap item di ORDER_ITEM:
      ↓
Simpan pilihan ke ORDER_ITEM_OPTION:
  {
    order_item_id:  id_order_item,
    option_item_id: id_pilihan,
    nama_snapshot:  "Keju",      ← disalin dari MENU_OPTION_ITEM.nama
    harga_snapshot: 3000,        ← disalin dari MENU_OPTION_ITEM.harga_tambah
  }

Satu ORDER_ITEM bisa punya banyak ORDER_ITEM_OPTION
(satu untuk setiap pilihan yang dipilih customer)
```

---

### 4.5 Tampilan di Dapur / Karyawan

```
Detail order yang masuk ke dapur:

Order #015 — Dine In — Meja 3
─────────────────────────────
1x Nasi Goreng Spesial
   → Sedang
   → Keju, Sosis
   Subtotal: Rp 33.000

1x Es Teh Manis
   → Sedikit Gula
   → Normal Es
   Subtotal: Rp 8.000
─────────────────────────────
Total: Rp 41.000
```

---

## 5. Perhitungan Harga

```
Harga akhir per item =
  harga dasar menu
  + SUM(harga_tambah semua pilihan yang dipilih)
  × qty

Contoh:
  Nasi Goreng Spesial    Rp 25.000
  + Topping Keju         Rp  3.000
  + Topping Sosis        Rp  5.000
  ─────────────────────────────────
  Harga per porsi        Rp 33.000
  × 2 porsi
  ─────────────────────────────────
  Subtotal item          Rp 66.000
```

---

## 6. Perubahan ERD

### Tabel baru yang ditambahkan:

```
+ VARIANT_TEMPLATE
+ VARIANT_TEMPLATE_ITEM
+ MENU_OPTION_GROUP
+ MENU_OPTION_ITEM
+ ORDER_ITEM_OPTION
```

### Relasi baru:

```
VARIANT_TEMPLATE    ||--o{ VARIANT_TEMPLATE_ITEM : "berisi"
MENU                ||--o{ MENU_OPTION_GROUP      : "punya kustomisasi"
MENU_OPTION_GROUP   ||--o{ MENU_OPTION_ITEM       : "berisi pilihan"
ORDER_ITEM          ||--o{ ORDER_ITEM_OPTION      : "punya pilihan"
MENU_OPTION_ITEM    ||--o{ ORDER_ITEM_OPTION      : "dirujuk oleh"
```

---

## 7. Aturan Bisnis

```
1. Satu menu boleh tidak punya grup kustomisasi sama sekali
   → menu simpel tanpa pilihan

2. Grup dengan tipe "single" → customer wajib pilih tepat 1 item
   (jika wajib: true)

3. Grup dengan tipe "multiple" → customer boleh pilih 0 atau lebih item

4. Grup yang wajib: false → customer boleh skip seluruh grup

5. Owner bisa hapus grup variant selama belum ada order aktif
   yang menggunakan menu tersebut

6. Perubahan harga variant tidak mempengaruhi order yang sudah masuk
   karena sudah disimpan sebagai snapshot

7. Template bawaan adalah referensi — setelah dipakai,
   data disalin ke MENU_OPTION_GROUP & MENU_OPTION_ITEM
   Perubahan template tidak mempengaruhi menu yang sudah ada
```

---

## 8. Urutan Pengerjaan

```
BACKEND / FIRESTORE:
1. Seed data VARIANT_TEMPLATE & VARIANT_TEMPLATE_ITEM
   (isi template bawaan: kepedasan, topping, gula, es)
         ↓
2. CRUD MENU_OPTION_GROUP
   (tambah, edit, hapus grup variant per menu)
         ↓
3. CRUD MENU_OPTION_ITEM
   (tambah, edit, hapus item dalam grup)
         ↓
4. Simpan ORDER_ITEM_OPTION saat order dibuat

FLUTTER — OWNER:
1. Tampilkan section kustomisasi di form tambah/edit menu
2. Bottom sheet pilih template atau buat custom
3. Form edit grup (nama, tipe, wajib, item-item)
4. Reorder grup dengan drag

FLUTTER — CUSTOMER:
1. Tampilkan grup variant di bottom sheet detail menu
2. Logika single select (radio) & multiple select (checkbox)
3. Validasi grup wajib sebelum tambah ke keranjang
4. Hitung subtotal real-time saat pilihan berubah

FLUTTER — KARYAWAN:
1. Tampilkan pilihan variant di detail order
   (baca dari ORDER_ITEM_OPTION)
```

---

## 9. Pembagian Tugas

| Tugas | Sisi |
|---|---|
| Seed template bawaan ke Firestore | Backend / Flutter (sekali jalan) |
| CRUD grup & item variant (owner) | Flutter langsung ke Firestore |
| Tampil & pilih variant (customer) | Flutter — rekan |
| Simpan ORDER_ITEM_OPTION saat order | Flutter / Node.js |
| Tampil pilihan di detail order (karyawan) | Flutter |
