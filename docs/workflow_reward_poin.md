# Workflow: Sistem Reward Poin — cariMakan

Dokumen ini menjelaskan alur kerja, formula perhitungan, dan logika implementasi
untuk fitur reward poin di aplikasi cariMakan.

---

## 1. Gambaran Umum

Sistem reward poin memberikan insentif kepada customer untuk terus bertransaksi
di cariMakan. Setiap transaksi yang selesai menghasilkan poin yang bisa
ditukarkan sebagai potongan harga di order berikutnya.

| Aspek | Aturan |
|---|---|
| Dapat poin | 0.5% dari total yang dibayar (setelah semua potongan) |
| Pembulatan | Floor / bulatkan ke bawah |
| Nilai tukar | 1 poin = Rp 1 potongan |
| Batas pakai | Maksimal 25% dari total order |
| Trigger dapat | Saat status order berubah jadi 'selesai' |
| Trigger pakai | Saat checkout sebelum bayar |

---

## 2. Formula Perhitungan

### 2.1 Mendapat Poin

```
poin_didapat = floor(total_akhir_dibayar × 0.5 / 100)

Keterangan:
  total_akhir_dibayar = total setelah semua potongan
                        (diskon promo + potongan poin)
  floor               = bulatkan ke bawah (bukan round)
```

Contoh:
```
Order Rp 50.000 (tanpa diskon, tanpa poin):
  poin = floor(50.000 × 0.005) = floor(250)    = 250 poin ✅

Order Rp 33.750 (tanpa diskon, tanpa poin):
  poin = floor(33.750 × 0.005) = floor(168.75) = 168 poin ✅

Order Rp 44.500 (setelah semua potongan):
  poin = floor(44.500 × 0.005) = floor(222.5)  = 222 poin ✅
```

### 2.2 Memakai Poin

```
maks_potongan_poin = floor(total_setelah_diskon × 25 / 100)
poin_terpakai      = min(poin_dimiliki, maks_potongan_poin)
potongan_rupiah    = poin_terpakai   (1 poin = Rp 1)
total_akhir        = total_setelah_diskon - potongan_rupiah
```

Contoh 1 — poin tidak cukup untuk mencapai batas:
```
Punya poin        : 500
Total order       : Rp 50.000
Setelah promo     : Rp 45.000
Maks potongan 25% : Rp 45.000 × 25% = Rp 11.250
Poin terpakai     : min(500, 11.250) = 500 poin
Potongan          : Rp 500
Total akhir       : Rp 44.500
Poin didapat      : floor(44.500 × 0.005) = 222 poin
```

Contoh 2 — poin lebih dari batas maksimal:
```
Punya poin        : 20.000
Total order       : Rp 50.000
Setelah promo     : Rp 45.000
Maks potongan 25% : Rp 45.000 × 25% = Rp 11.250
Poin terpakai     : min(20.000, 11.250) = 11.250 poin  ← dibatasi
Potongan          : Rp 11.250
Total akhir       : Rp 33.750
Sisa poin         : 20.000 - 11.250 = 8.750 poin
Poin didapat      : floor(33.750 × 0.005) = 168 poin
```

---

## 3. Urutan Potongan saat Checkout

```
Total order mentah (sum semua item + variant)
          ↓
- Potongan promo / voucher (jika ada)
          ↓
= Subtotal setelah diskon
          ↓
- Potongan poin (jika customer pilih pakai poin)
  maks 25% dari subtotal setelah diskon
          ↓
= Total akhir yang dibayar ke Midtrans
          ↓
= Basis perhitungan poin yang didapat
```

Visualisasi:
```
Total order              Rp 50.000
- Diskon MAKAN20       - Rp  5.000
──────────────────────────────────
Subtotal                 Rp 45.000
- Pakai 500 poin       - Rp    500
──────────────────────────────────
Total bayar              Rp 44.500
Poin didapat       floor(44.500 × 0.005) = 222 poin
```

---

## 4. Alur Lengkap

### 4.1 Mendapat Poin (setelah order selesai)

```
[Node.js — dipicu saat status ORDER berubah jadi 'selesai']

Ambil data order:
  total_akhir = order.total   ← total yang benar-benar dibayar
      ↓
Hitung poin:
  poin_didapat = floor(total_akhir × 0.5 / 100)
      ↓
Jika poin_didapat > 0:
  UPDATE users/{uid} {
    poin_reward: poin_reward + poin_didapat
  }
  INSERT reward_poin {
    user_id:      uid_customer,
    order_id:     id_order,
    jumlah_poin:  poin_didapat,
    tipe:         'earn',
    keterangan:   "Order #001 di Warteg Pak Budi",
    created_at:   serverTimestamp()
  }
      ↓
Kirim push notif FCM ke customer:
  "Selamat! Kamu mendapat {poin_didapat} poin
   dari order di [Nama Resto]. Total poin: {total_poin}"
```

### 4.2 Memakai Poin saat Checkout

```
[Flutter — Customer]

Di halaman checkout, ada section:
  ┌──────────────────────────────────────────┐
  │ 💰 Reward Poin                           │
  │ Poin kamu: 500 poin (= Rp 500)          │
  │                                          │
  │ [Toggle] Pakai poin                      │
  │ Potongan: Rp 500                         │
  │ Maks pakai: Rp 11.250 (25% dari order)  │
  └──────────────────────────────────────────┘

Customer toggle ON → sistem hitung otomatis:
  maks_potongan  = floor(subtotal × 0.25)
  poin_dipakai   = min(poin_dimiliki, maks_potongan)
  total berubah di UI secara real-time
      ↓
Customer klik [Bayar]
      ↓
Flutter kirim ke Node.js:
  {
    order_id:     id_order,
    pakai_poin:   true,
    poin_dipakai: 500,
    total_akhir:  44500
  }
      ↓
Node.js validasi ulang (jangan percaya Flutter):
  → cek poin customer di Firestore (bukan dari Flutter)
  → hitung ulang maks potongan
  → pastikan tidak over
      ↓
Jika valid → proses ke Midtrans dengan total_akhir
      ↓
Setelah pembayaran sukses:
  UPDATE users/{uid} {
    poin_reward: poin_reward - poin_dipakai
  }
  INSERT reward_poin {
    user_id:      uid_customer,
    order_id:     id_order,
    jumlah_poin:  -500,          ← negatif = pengeluaran poin
    tipe:         'redeem',
    keterangan:   "Dipakai untuk Order #002",
    created_at:   serverTimestamp()
  }
```

---

## 5. Riwayat Poin (Halaman Customer)

```
Halaman Poin & Reward

  Total Poin Kamu
  ┌──────────────┐
  │  💰 1.250    │
  │    poin      │
  └──────────────┘
  Setara dengan Rp 1.250 potongan

  ── Riwayat Poin ──────────────────────────
  ▲ +222 poin   Order di Warteg Pak Budi    14 Jan
  ▼ -500 poin   Dipakai untuk Order #002    13 Jan
  ▲ +168 poin   Order di Bakso Bang Tigor   12 Jan
  ▲ +250 poin   Order di Warteg Pak Budi    10 Jan

  (▲ = dapat poin, ▼ = pakai poin)
```

Query riwayat poin:
```
collection : reward_poin
WHERE user_id == uid_customer
ORDER BY created_at DESC
```

---

## 6. Aturan Bisnis

```
1. Poin hanya didapat setelah status order = 'selesai'
   → Tidak bisa dapat poin dari order yang dibatalkan/gagal

2. Poin dihitung dari total yang benar-benar dibayar
   → Setelah semua potongan (promo + poin itu sendiri)
   → Bukan dari harga mentah sebelum diskon

3. Pembulatan selalu ke bawah (floor)
   → floor(168.75) = 168, bukan 169

4. Maksimal pemakaian poin = 25% dari subtotal setelah diskon
   → Tidak bisa bayar full pakai poin

5. Poin tidak bisa di-redeem jika tidak cukup
   → Sistem otomatis batasi sesuai poin yang dimiliki

6. Validasi poin dilakukan di Node.js, bukan Flutter
   → Untuk mencegah manipulasi dari client side

7. Poin tidak kadaluarsa (tidak ada expired date)

8. Poin hanya berlaku untuk role 'customer'
   → Owner, karyawan, admin: poin_reward selalu 0, tidak dipakai

9. Jika order gagal setelah poin sudah dikurang
   → Node.js wajib kembalikan poin (rollback)
   → INSERT reward_poin tipe 'refund' + jumlah positif
```

---

## 7. Edge Case yang Perlu Ditangani

```
Edge case 1 — Poin habis di tengah jalan:
  Customer punya 500 poin saat checkout
  Tapi ternyata di server hanya 300 poin (sudah dipakai di device lain)
  → Node.js validasi → pakai 300 poin saja
  → Notif ke customer: "Poin yang dipakai disesuaikan menjadi 300 poin"

Edge case 2 — Order gagal setelah bayar:
  Customer bayar Rp 44.500 (pakai 500 poin)
  Payment sukses tapi order gagal dibuat di Firestore
  → Node.js rollback: kembalikan 500 poin ke customer
  → Refund pembayaran ke customer

Edge case 3 — Total order setelah poin jadi 0:
  Tidak mungkin terjadi karena batas maks 25%
  → Minimal customer tetap bayar 75% dari subtotal
```

---

## 8. Urutan Pengerjaan

```
NODE.JS:
1. Endpoint POST /poin/tambah
   → dipanggil setelah order status = 'selesai'
   → hitung poin, update USER, insert REWARD_POIN
         ↓
2. Endpoint POST /poin/validasi-redeem
   → validasi poin yang mau dipakai saat checkout
   → return jumlah poin valid + potongan rupiah
         ↓
3. Endpoint POST /poin/redeem
   → kurangi poin setelah pembayaran sukses
   → insert REWARD_POIN tipe 'redeem'
         ↓
4. Endpoint POST /poin/rollback
   → kembalikan poin jika order/payment gagal

FLUTTER — CUSTOMER (rekan):
1. Tampilkan total poin di profil & checkout
2. Toggle pakai poin di halaman checkout
   → hitung potongan real-time saat toggle ON
3. Halaman riwayat poin
   → list earn & redeem dengan ikon berbeda

FLUTTER — SEMUA ROLE:
  Owner, karyawan, admin → tidak ada UI poin sama sekali
```

---

## 9. Pembagian Tugas

| Tugas | Dikerjakan oleh |
|---|---|
| Hitung & tambah poin setelah order selesai | Tim Backend (Node.js) |
| Validasi & kurangi poin saat checkout | Tim Backend (Node.js) |
| Rollback poin jika order/payment gagal | Tim Backend (Node.js) |
| Tampil total poin di profil customer | Rekan (Flutter Customer) |
| Toggle pakai poin di checkout | Rekan (Flutter Customer) |
| Kalkulasi potongan real-time di UI | Rekan (Flutter Customer) |
| Halaman riwayat poin (earn & redeem) | Rekan (Flutter Customer) |
| FCM notif dapat poin setelah order selesai | Tim Backend (Node.js) |
