# Workflow: Sistem Manajemen Promo & Voucher — cariMakan

Dokumen ini menjelaskan alur kerja, struktur data, dan logika validasi
untuk fitur promo dan voucher di aplikasi cariMakan.

---

## 1. Gambaran Umum

Sistem promo di cariMakan mendukung dua jenis pembuat promo:

| Jenis | Dibuat oleh | Berlaku di |
|---|---|---|
| Promo Global | Admin | Semua resto di platform |
| Promo Resto | Owner Resto | Hanya di resto yang bersangkutan |

Setiap promo hanya bisa dipakai **sekali per customer**. Sistem otomatis
memvalidasi kelayakan promo sebelum bisa diterapkan ke order.

---

## 2. Struktur Data

### Tabel PROMO_VOUCHER
```
PROMO_VOUCHER {
  id            string    PK
  created_by    string    FK → user_id Admin atau Owner
  resto_id      string?   FK → NULL = global (Admin)
                               ISI  = promo resto (Owner)
  user_id       string?   FK → NULL = bisa dipakai semua customer
                               ISI  = voucher spesifik 1 customer

  nama          string    "Promo Makan Siang"
  deskripsi     string    "Hemat 20% untuk order di atas 50rb"
  kode          string?   "MAKAN20" — opsional, bisa tanpa kode

  nilai_diskon  int       nominal atau persen (lihat is_percent)
  is_percent    bool      true = persen | false = nominal
  maks_diskon   int?      batas maksimal potongan jika pakai persen
                          NULL = tidak dibatasi
                          contoh: diskon 20% tapi maks Rp 50.000

  min_belanja   int       syarat minimum total belanja
                          0 = tidak ada syarat
  min_item      int       syarat minimum jumlah item di order
                          0 = tidak ada syarat

  mulai         timestamp kapan promo mulai berlaku
  berakhir      timestamp kapan promo berakhir

  is_active     bool      true = aktif | false = dimatikan manual
}
```

### Tabel VOUCHER_PAKAI
```
VOUCHER_PAKAI {
  id        string     PK
  promo_id  string     FK → PROMO_VOUCHER
  user_id   string     FK → USER (customer yang pakai)
  order_id  string     FK → ORDER (dipakai di order mana)
  used_at   timestamp  kapan dipakai
}
```

> Tabel ini yang jadi penjaga agar satu customer tidak bisa pakai
> promo yang sama lebih dari sekali.

---

## 3. Kenapa Syarat Tidak Boleh Pakai String

```
❌ Pendekatan salah:
syarat: "Minimum belanja Rp 50.000 dan minimal 3 item"

→ Sistem hanya bisa tampilkan teks ini
→ Tidak bisa otomatis cek apakah order memenuhi syarat
→ Validasi harus dilakukan manual oleh manusia

✅ Pendekatan benar:
min_belanja: 50000
min_item: 3

→ Sistem bisa langsung bandingkan:
   order.total >= promo.min_belanja  → true / false
   order.jumlahItem >= promo.min_item → true / false
→ Validasi otomatis, tidak perlu campur tangan manusia
```

---

## 4. Alur Lengkap

### 4.1 Owner Membuat Promo

```
[Flutter — Owner]
Owner buka halaman Promo di dashboard
      ↓
Klik [+ Buat Promo Baru]
      ↓
Isi form:
  • Nama promo
  • Deskripsi
  • Kode promo (opsional)
  • Jenis diskon: Persen atau Nominal
      → jika Persen: isi nilai (%) + batas maksimal potongan (Rp)
      → jika Nominal: isi nilai potongan (Rp)
  • Syarat minimum belanja (Rp) — isi 0 jika tidak ada syarat
  • Syarat minimum item      — isi 0 jika tidak ada syarat
  • Tanggal mulai
  • Tanggal berakhir
      ↓
Klik [Simpan]
      ↓
Simpan ke Firestore: PROMO_VOUCHER {
  created_by: uid_owner,
  resto_id: id_resto_owner,   ← otomatis diisi, bukan input manual
  is_active: true,
  ...field lainnya dari form
}
      ↓
Promo langsung aktif dan bisa dipakai customer
di resto tersebut
```

---

### 4.2 Admin Membuat Promo Global

```
[Web App — Admin]
Sama seperti flow owner, bedanya:

  resto_id: NULL   ← promo berlaku di semua resto
  created_by: uid_admin
```

---

### 4.3 Customer Memakai Promo

```
[Flutter — Customer]
Customer sudah isi keranjang, masuk ke halaman checkout
      ↓
Klik [Pakai Promo] atau masukkan kode promo
      ↓
Sistem jalankan validasi bertahap:

  ┌─────────────────────────────────────────────────┐
  │ STEP 1 — Cek promo ditemukan                    │
  │ query PROMO_VOUCHER WHERE kode == input          │
  │ Tidak ada? → "Kode promo tidak ditemukan"        │
  └─────────────────────────────────────────────────┘
                        ↓
  ┌─────────────────────────────────────────────────┐
  │ STEP 2 — Cek is_active                          │
  │ is_active == false?                             │
  │ → "Promo sudah tidak aktif"                     │
  └─────────────────────────────────────────────────┘
                        ↓
  ┌─────────────────────────────────────────────────┐
  │ STEP 3 — Cek masa berlaku                       │
  │ waktu sekarang < mulai?                         │
  │ → "Promo belum mulai"                           │
  │ waktu sekarang > berakhir?                      │
  │ → "Promo sudah berakhir"                        │
  └─────────────────────────────────────────────────┘
                        ↓
  ┌─────────────────────────────────────────────────┐
  │ STEP 4 — Cek sudah pernah dipakai               │
  │ query VOUCHER_PAKAI                             │
  │ WHERE promo_id == id_promo                      │
  │ AND   user_id  == id_customer                   │
  │ Ada hasil? → "Kamu sudah pernah pakai promo ini"│
  └─────────────────────────────────────────────────┘
                        ↓
  ┌─────────────────────────────────────────────────┐
  │ STEP 5 — Cek syarat minimum belanja             │
  │ order.total < promo.min_belanja?                │
  │ → "Minimum belanja Rp {min_belanja}"            │
  └─────────────────────────────────────────────────┘
                        ↓
  ┌─────────────────────────────────────────────────┐
  │ STEP 6 — Cek syarat minimum item                │
  │ order.jumlahItem < promo.min_item?              │
  │ → "Minimum {min_item} item dalam pesanan"       │
  └─────────────────────────────────────────────────┘
                        ↓
  ┌─────────────────────────────────────────────────┐
  │ STEP 7 — Semua lolos → hitung potongan          │
  │                                                 │
  │ if is_percent:                                  │
  │   potongan = total × (nilai_diskon / 100)       │
  │   if maks_diskon != null:                       │
  │     potongan = min(potongan, maks_diskon)       │
  │ else:                                           │
  │   potongan = nilai_diskon                       │
  │                                                 │
  │ total_akhir = total_order - potongan            │
  └─────────────────────────────────────────────────┘
                        ↓
Tampilkan ringkasan di checkout:
  Subtotal          Rp 75.000
  Diskon MAKAN20  - Rp 15.000
  ─────────────────────────
  Total             Rp 60.000
      ↓
Customer konfirmasi & bayar
      ↓
Setelah pembayaran sukses:
  → Tulis ke VOUCHER_PAKAI {
      promo_id: id_promo,
      user_id: id_customer,
      order_id: id_order,
      used_at: sekarang
    }
  → Simpan promo_id ke ORDER.promo_id
```

---

### 4.4 Owner Menonaktifkan Promo

```
[Flutter — Owner]
Owner buka daftar promo
      ↓
Klik [Nonaktifkan] pada promo yang ingin dimatikan
      ↓
Update Firestore: PROMO_VOUCHER.is_active = false
      ↓
Promo langsung tidak bisa dipakai customer
(tanpa perlu hapus data)
```

---

## 5. Contoh Perhitungan Diskon

### Contoh 1 — Diskon Nominal
```
Promo: Potongan Rp 20.000
  nilai_diskon : 20000
  is_percent   : false
  min_belanja  : 50000
  min_item     : 0

Order total: Rp 75.000 ✅ (memenuhi min. belanja)
Potongan   : Rp 20.000
Total akhir: Rp 55.000
```

### Contoh 2 — Diskon Persen tanpa batas
```
Promo: Diskon 20%
  nilai_diskon : 20
  is_percent   : true
  maks_diskon  : NULL
  min_belanja  : 0

Order total: Rp 200.000
Potongan   : Rp 200.000 × 20% = Rp 40.000
Total akhir: Rp 160.000
```

### Contoh 3 — Diskon Persen dengan batas maksimal
```
Promo: Diskon 20% (maks. Rp 30.000)
  nilai_diskon : 20
  is_percent   : true
  maks_diskon  : 30000
  min_belanja  : 0

Order total: Rp 200.000
Potongan raw: Rp 200.000 × 20% = Rp 40.000
Potongan aktual: min(40.000, 30.000) = Rp 30.000  ← dibatasi
Total akhir: Rp 170.000
```

### Contoh 4 — Syarat tidak terpenuhi
```
Promo: Diskon 10% (min. belanja Rp 50.000, min. 3 item)
  min_belanja : 50000
  min_item    : 3

Order total : Rp 35.000  ❌ kurang dari min. belanja
Order item  : 2 item     ❌ kurang dari min. item
→ Promo tidak bisa dipakai
→ Tampilkan: "Minimum belanja Rp 50.000 dan minimal 3 item"
```

---

## 6. Tampilan di Aplikasi

### Halaman Daftar Promo (Customer)
```
Menampilkan promo yang tersedia untuk customer:
  • Promo global (resto_id == NULL)
  • Promo resto yang sedang dikunjungi/dipesan

Setiap card promo menampilkan:
  • Nama & deskripsi promo
  • Nilai diskon (Rp X atau X%)
  • Syarat (min. belanja, min. item)
  • Masa berlaku
  • Status: Tersedia / Sudah Dipakai / Tidak Memenuhi Syarat
```

### Halaman Kelola Promo (Owner)
```
Daftar promo yang sudah dibuat:
  • Nama promo + kode
  • Nilai diskon
  • Masa berlaku
  • Status: Aktif / Nonaktif
  • Jumlah pemakaian (COUNT dari VOUCHER_PAKAI)

Aksi per promo:
  • Edit (selama belum ada yang pakai)
  • Nonaktifkan / Aktifkan kembali
  • Hapus (selama belum ada yang pakai)
```

---

## 7. Aturan Bisnis Penting

```
1. Promo hanya bisa diedit/dihapus jika belum ada customer
   yang memakainya (VOUCHER_PAKAI kosong untuk promo ini)

2. Satu order hanya bisa pakai satu promo

3. Satu customer hanya bisa pakai promo yang sama sekali

4. Promo resto hanya berlaku di resto yang membuat promo tersebut
   → validasi: promo.resto_id == order.resto_id

5. Promo global berlaku di semua resto
   → promo.resto_id == NULL → skip cek resto

6. Potongan tidak boleh melebihi total order
   → total_akhir = max(0, total_order - potongan)
   → total tidak bisa minus

7. Promo yang sudah berakhir (waktu > berakhir) tidak bisa dipakai
   meskipun is_active == true
```

---

## 8. Pembagian Tugas Implementasi

| Tugas | Sisi |
|---|---|
| Form buat promo (Owner dashboard) | Flutter |
| Form buat promo global (Admin web) | Web App |
| Daftar & kelola promo (Owner) | Flutter |
| Tampilkan promo tersedia (Customer checkout) | Flutter |
| Validasi promo step 1-6 | Flutter (atau Node.js) |
| Hitung potongan diskon | Flutter (atau Node.js) |
| Tulis VOUCHER_PAKAI setelah bayar | Node.js (bersamaan dengan payment) |
| Nonaktifkan / hapus promo | Flutter → Firestore langsung |
