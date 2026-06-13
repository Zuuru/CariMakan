# Workflow: Sistem Pesanan (Order) — cariMakan

Dokumen ini menjelaskan alur kerja, struktur query, dan logika implementasi
untuk fitur daftar pesanan di sisi Customer dan Karyawan.

---

## 1. Gambaran Umum

Sistem pesanan menghubungkan Customer dan Karyawan secara real-time melalui
Firestore. Customer melihat status pesanannya, Karyawan memproses dan
mengupdate statusnya.

| Aktor | Akses |
|---|---|
| Customer | Lihat pesanan miliknya sendiri saja |
| Karyawan | Lihat pesanan dari restonya saja |
| Owner | Lihat semua pesanan restonya (via dashboard) |

---

## 2. Struktur Query

### 2.1 Query Pesanan — Sisi Customer

```
Prinsip utama:
Filter berdasarkan user_id yang sedang login
→ Customer A tidak akan pernah lihat pesanan Customer B

Query pesanan aktif (sedang diproses):
  collection : orders
  WHERE user_id        == uid_customer_login   ← kunci utama
  WHERE status         IN ['pending','proses','siap']
  ORDER BY created_at  DESC

Query pesanan selesai:
  collection : orders
  WHERE user_id        == uid_customer_login   ← kunci utama
  WHERE status         == 'selesai'
  ORDER BY created_at  DESC
```

### 2.2 Query Pesanan — Sisi Karyawan

```
Prinsip utama:
Filter berdasarkan resto_id yang terdaftar di akun karyawan
→ Karyawan Resto A tidak akan pernah lihat pesanan Resto B

Query semua pesanan aktif resto:
  collection : orders
  WHERE resto_id       == resto_id_karyawan   ← kunci utama
  WHERE status         IN ['pending','proses','siap']
  ORDER BY created_at  ASC   ← urutan masuk, yang lama dulu

Query per tipe:
  + WHERE tipe == 'dinein'    ← tab Dine In
  + WHERE tipe == 'takeaway'  ← tab Take Away
```

---

## 3. Tampilan Daftar Pesanan — Customer

### 3.1 Struktur Halaman

```
HalamanPesananCustomer
│
├── Tab: Sedang Diproses
│   ├── Section: Dine In
│   │   ├── Card Pesanan #001
│   │   └── Card Pesanan #003
│   └── Section: Take Away
│       └── Card Pesanan #002
│
└── Tab: Pesanan Selesai
    ├── Section: Dine In
    │   └── Card Pesanan #005
    └── Section: Take Away
        └── Card Pesanan #004
```

### 3.2 Card Pesanan di List

```
┌─────────────────────────────────────────────┐
│ Resto Pak Budi               Dine In Meja 3 │
│ ─────────────────────────────────────────── │
│ Nasi Goreng Spesial  ×1                     │
│ Es Teh Manis         ×2                     │
│ + 1 item lainnya...                         │
│ ─────────────────────────────────────────── │
│ Total: Rp 33.000          12 Jan · 12:35    │
│                                             │
│ ● SEDANG DIPROSES                [Detail >] │
└─────────────────────────────────────────────┘
```

Warna status di card:
```
pending  → abu-abu   "Menunggu Konfirmasi"
proses   → biru      "Sedang Diproses"
siap     → hijau     "Pesanan Siap!"
selesai  → abu gelap "Selesai"
```

---

## 4. Tampilan Detail Pesanan — Customer

### 4.1 Tracker Status (Real-time)

```
Tracker ditampilkan di bagian atas halaman detail.
Update otomatis saat karyawan mengubah status di Firestore.

─── Dine In ──────────────────────────────────────

  ●────────●────────○────────○
  Pesanan    Sedang    Pesanan   Selesai
  Diterima   Diproses  Siap

  ● = sudah lewat (warna aktif)
  ○ = belum (warna abu)

─── Take Away ────────────────────────────────────

  ●────────●────────○────────○────────○
  Pesanan    Sedang    Pesanan   Siap      Pesanan
  Diterima   Diproses  Siap      Diambil   Selesai

Mapping status ORDER ke step tracker:
  pending  → step 1 aktif
  proses   → step 1-2 aktif
  siap     → step 1-3 aktif
  selesai  → semua step aktif
```

### 4.2 Detail Isi Pesanan

```
┌─────────────────────────────────────────────┐
│ DETAIL PESANAN                              │
│ Order #001  ·  12 Jan 2025  ·  12:35        │
│                                             │
│ Resto  : Warteg Pak Budi                    │
│ Tipe   : Dine In                            │
│ Meja   : Meja 3              ← dari MEJA    │
│                                             │
│ ── Pesanan ───────────────────────────────  │
│ Nasi Goreng Spesial                         │
│   → Sedang, Topping Keju                    │  ← variant
│   ×1                        Rp 28.000       │
│                                             │
│ Es Teh Manis                                │
│   → Sedikit Gula                            │
│   ×2                        Rp 16.000       │
│                                             │
│ ── Rincian Harga ─────────────────────────  │
│ Subtotal                    Rp 44.000       │
│ Diskon MAKAN20            - Rp  5.000       │
│ ─────────────────────────────────────────── │
│ Total                       Rp 39.000       │
│                                             │
│ Pembayaran : QRIS                           │
│ Status     : Lunas ✓                        │
└─────────────────────────────────────────────┘
```

### 4.3 Aturan Tampilan Meja

```
Tipe dinein   → tampilkan "Meja {nomor_meja}"
                ambil dari MEJA WHERE id == order.meja_id

Tipe takeaway → tampilkan "Pickup pukul {jam_pickup}"
                tidak ada info meja
```

---

## 5. Alur Update Status — Karyawan

### 5.1 Tampilan Karyawan (Review dari workflow sebelumnya)

```
KaryawanHomePage
│
├── Tab: Dine In
│   ├── Card Order #001 · Meja 3 · [MENUNGGU]
│   └── Card Order #004 · Meja 7 · [DIPROSES]
│
└── Tab: Take Away
    └── Card Order #002 · Pickup 13:00 · [MENUNGGU]
```

### 5.2 Alur Update Status via Bottom Sheet

```
Karyawan klik card order
      ↓
Bottom sheet muncul — tampilkan detail order:
  • Nomor order + waktu masuk
  • Tipe: Dine In (nomor meja) / Take Away (jam pickup)
  • Daftar item + variant yang dipilih customer
  • Status saat ini

  Tombol aksi (muncul sesuai status saat ini):

  ┌─────────────────────────────────────────┐
  │ Status: MENUNGGU                        │
  │                                         │
  │        [Mulai Proses]                   │
  └─────────────────────────────────────────┘

  ┌─────────────────────────────────────────┐
  │ Status: DIPROSES                        │
  │                                         │
  │        [Tandai Siap]                    │
  └─────────────────────────────────────────┘

  ┌─────────────────────────────────────────┐
  │ Status: SIAP                            │
  │ (Take Away only)                        │
  │        [Scan QR Pickup]                 │
  └─────────────────────────────────────────┘
```

### 5.3 Logic Update Status di Firestore

```
Karyawan klik [Mulai Proses]:
  UPDATE orders/{id} {
    status:          'proses',
    status_antrian:  'diproses',
    updated_at:      serverTimestamp()
  }
  → Trigger push notif FCM ke customer:
    "Pesanan kamu sedang diproses oleh resto!"

Karyawan klik [Tandai Siap]:
  UPDATE orders/{id} {
    status:          'siap',
    status_antrian:  'selesai',
    updated_at:      serverTimestamp()
  }
  → Trigger push notif FCM ke customer:
    Dine In  : "Pesanan kamu sudah siap! Silakan ambil."
    Take Away: "Pesanan kamu siap diambil!"

Karyawan scan QR Pickup (Take Away):
  Validasi QR:
    decode QR → ambil order_id
    cek order_id valid & milik resto ini
    cek status == 'siap'
    cek tipe == 'takeaway'
  Semua valid:
  UPDATE orders/{id} {
    status:      'selesai',
    updated_at:  serverTimestamp()
  }
  → Trigger reward poin ke customer
  → Order hilang dari list aktif karyawan
```

---

## 6. Alur Real-time — Bagaimana Tracker Customer Update Otomatis

```
Karyawan update status di Firestore
            ↓
Firestore deteksi perubahan dokumen
            ↓
Stream listener di Flutter Customer aktif
            ↓
UI tracker otomatis rebuild tanpa refresh manual

Implementasi di Flutter:

StreamBuilder(
  stream: FirebaseFirestore.instance
    .collection('orders')
    .doc(orderId)
    .snapshots(),         ← listen 1 dokumen saja
  builder: (context, snapshot) {
    final status = snapshot.data?['status'];
    return TrackerWidget(status: status);
  }
)

Tidak perlu polling, tidak perlu refresh —
Firestore push perubahan ke Flutter secara otomatis.
```

---

## 7. Keamanan Data — Siapa Bisa Lihat Apa

```
Customer A login:
  Query: WHERE user_id == uid_A
  → Hanya muncul pesanan milik A
  → Pesanan B, C, D tidak pernah di-fetch

Karyawan Resto X login:
  Query: WHERE resto_id == id_resto_X
  → Hanya muncul pesanan yang masuk ke Resto X
  → Pesanan Resto Y, Z tidak pernah di-fetch

Firestore Rules (lapisan keamanan tambahan):
  match /orders/{orderId} {
    allow read: if
      request.auth.uid == resource.data.user_id    // customer pemilik order
      || request.auth.uid == resource.data.karyawan_resto_id  // karyawan resto
      || isOwnerOfResto(resource.data.resto_id);   // owner resto

    allow update: if
      isKaryawanOfResto(resource.data.resto_id);   // hanya karyawan resto ini
  }
```

---

## 8. Push Notifikasi per Perubahan Status

| Status Berubah | Notif ke Customer | Isi Notif |
|---|---|---|
| pending → proses | ✅ Ya | "Pesanan kamu sedang diproses!" |
| proses → siap (dine in) | ✅ Ya | "Pesanan siap! Silakan ambil." |
| proses → siap (takeaway) | ✅ Ya | "Pesanan siap diambil!" |
| siap → selesai | ✅ Ya | "Terima kasih! Pesanan selesai. Beri ulasan?" |

Notif dikirim via Firebase Cloud Messaging (FCM) dari Node.js
setiap kali Karyawan update status order.

---

## 9. Trigger Setelah Pesanan Selesai

```
Status ORDER berubah jadi 'selesai'
            ↓
Node.js (via Firestore trigger / webhook):

1. Tambah poin reward ke customer:
   UPDATE users/{uid} { poin_reward += jumlah_poin }
   INSERT reward_poin { user_id, order_id, jumlah_poin }

2. Update avg_rating resto (jika sudah direview):
   → dikerjakan saat customer submit review, bukan di sini

3. Kirim notif ke customer:
   "Pesanan selesai! Kamu mendapat X poin reward."
   + prompt untuk beri ulasan
```

---

## 10. Urutan Pengerjaan

```
FLUTTER — CUSTOMER (rekan):
1. Buat halaman daftar pesanan
   → query Firestore realtime by user_id
   → 2 tab: Diproses & Selesai
   → tiap tab dibagi section Dine In & Take Away
         ↓
2. Buat card pesanan di list
   → tampilkan info singkat + status
         ↓
3. Buat halaman detail pesanan
   → tracker status real-time
   → daftar item + variant
   → info meja (dine in) atau jam pickup (takeaway)
   → rincian harga + diskon
         ↓
4. Pasang StreamBuilder untuk listen perubahan status

FLUTTER — KARYAWAN (lo):
1. Buat list order aktif resto (by resto_id)
   → 2 tab: Dine In & Take Away
   → StreamBuilder realtime
         ↓
2. Buat bottom sheet detail order
   → tampilkan item + variant pilihan customer
         ↓
3. Tombol update status
   → Mulai Proses → update Firestore
   → Tandai Siap  → update Firestore
   → Scan QR Pickup (take away) → validasi QR → update Firestore
         ↓
4. Trigger push notif ke customer setelah update status

NODE.JS:
1. Endpoint kirim FCM setelah status update
2. Endpoint tambah poin reward setelah order selesai
```

---

## 11. Pembagian Tugas

| Tugas | Dikerjakan oleh |
|---|---|
| Halaman daftar & detail pesanan (customer) | Rekan (Flutter Customer) |
| Tracker status real-time (customer) | Rekan (Flutter Customer) |
| List order aktif (karyawan) | Lo (Flutter Owner/Karyawan) |
| Bottom sheet detail + tombol update status | Lo (Flutter Owner/Karyawan) |
| Scan QR pickup (karyawan) | Lo (Flutter Owner/Karyawan) |
| Kirim FCM notif setelah update status | Tim Backend (Node.js) |
| Tambah poin reward setelah selesai | Tim Backend (Node.js) |
| Firestore security rules | Tim Backend / lo |
