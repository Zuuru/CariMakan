# Workflow: Sistem Pendaftaran Karyawan — cariMakan

Dokumen ini menjelaskan alur kerja, kebutuhan teknis, dan langkah implementasi
untuk fitur pendaftaran akun karyawan oleh Owner Resto.

---

## 1. Gambaran Umum

Fitur ini memungkinkan Owner Resto untuk membuat akun karyawan langsung dari
aplikasi Flutter tanpa perlu persetujuan Admin. Akun yang berhasil dibuat
langsung aktif dan bisa digunakan karyawan untuk login ke tampilan khusus
karyawan.

---

## 2. Aktor yang Terlibat

| Aktor | Peran |
|---|---|
| Owner Resto | Membuat, mensuspend, dan menghapus akun karyawan |
| Karyawan | Menerima akun dari owner, login ke tampilan karyawan |
| Node.js Backend | Membuat akun Firebase Auth tanpa logout owner |
| Firebase Auth | Menyimpan kredensial login karyawan |
| Firestore | Menyimpan data profil karyawan |

---

## 3. Kenapa Harus Lewat Node.js?

Firebase Auth di sisi client (Flutter) tidak bisa membuat akun orang lain
tanpa logout dari akun yang sedang aktif.

```
❌ Tanpa Node.js:
Owner login → createUserWithEmailAndPassword(email karyawan)
→ Firebase otomatis logout owner & login sebagai karyawan baru
→ Owner kehilangan sesi loginnya

✅ Dengan Node.js (Firebase Admin SDK):
Owner login → kirim request ke Node.js
→ Node.js buat akun via Admin SDK (tidak ganggu sesi siapapun)
→ Akun karyawan langsung jadi, owner tetap login
```

---

## 4. Alur Lengkap

### 4.1 Membuat Akun Karyawan

```
[Flutter — Owner]
Owner buka halaman Profil
      ↓
Klik menu "Manajemen Karyawan"
      ↓
Klik tombol [+ Tambah Karyawan]
      ↓
Isi form:
  • Nama karyawan
  • Email (akan dipakai untuk login)
  • Password awal
      ↓
Klik [Simpan]
      ↓
Flutter ambil ID Token owner dari Firebase Auth
(sebagai bukti bahwa yang request adalah owner yang valid)
      ↓
Kirim HTTP POST ke Node.js:
  Header: Authorization: Bearer {idToken}
  Body: { nama, email, password, resto_id }

─────────────────────────────────────────────

[Node.js Backend]
Terima request
      ↓
Verifikasi ID Token owner via Firebase Admin SDK
→ pastikan token valid
→ pastikan role user == 'owner'
→ pastikan resto_id yang dikirim memang milik owner ini
      ↓
Buat akun Firebase Auth via Admin SDK:
  admin.auth().createUser({ email, password, displayName: nama })
      ↓
Tulis dokumen USER ke Firestore:
  users/{uid} {
    id: uid,
    nama: nama,
    email: email,
    role: 'karyawan',
    status: 'aktif',
    resto_id: resto_id,
    poin_reward: 0,
    fcm_token: null,
    foto_url: null,
    url_whatsapp: null,
    created_at: serverTimestamp()
  }
      ↓
Return response sukses:
  { uid, nama, email, resto_id, status }

─────────────────────────────────────────────

[Flutter — Owner]
Terima response sukses
      ↓
List karyawan otomatis update (Firestore realtime)
      ↓
Tampilkan snackbar "Akun karyawan berhasil dibuat"
      ↓
Owner kasih email + password ke karyawan secara manual
```

---

### 4.2 Suspend Akun Karyawan

```
[Flutter — Owner]
Owner klik opsi [Suspend] pada card karyawan
      ↓
Muncul dialog konfirmasi
      ↓
Owner konfirmasi
      ↓
Flutter kirim HTTP PATCH ke Node.js:
  Header: Authorization: Bearer {idToken}
  Body: { uid: uid_karyawan }

─────────────────────────────────────────────

[Node.js Backend]
Verifikasi token owner
      ↓
Disable akun di Firebase Auth:
  admin.auth().updateUser(uid, { disabled: true })
      ↓
Update status di Firestore:
  users/{uid} { status: 'suspend' }
      ↓
Return response sukses

─────────────────────────────────────────────

[Flutter — Owner]
List karyawan update otomatis
Status karyawan berubah jadi "Suspend"
```

---

### 4.3 Hapus Akun Karyawan

```
[Flutter — Owner]
Owner klik opsi [Hapus] pada card karyawan
      ↓
Muncul dialog konfirmasi
      ↓
Owner konfirmasi
      ↓
Flutter kirim HTTP DELETE ke Node.js:
  Header: Authorization: Bearer {idToken}
  Param: /karyawan/:uid

─────────────────────────────────────────────

[Node.js Backend]
Verifikasi token owner
      ↓
Hapus akun di Firebase Auth:
  admin.auth().deleteUser(uid)
      ↓
Hapus dokumen di Firestore:
  users/{uid} → delete
      ↓
Return response sukses

─────────────────────────────────────────────

[Flutter — Owner]
List karyawan update otomatis
Card karyawan hilang dari list
```

---

### 4.4 Login sebagai Karyawan

```
[Flutter — Karyawan]
Karyawan buka app
      ↓
Masukkan email + password yang diberikan owner
      ↓
Firebase Auth verifikasi kredensial
      ↓
AuthWrapper ambil dokumen USER dari Firestore
      ↓
Cek role == 'karyawan'
      ↓
Cek status == 'aktif'
  → jika 'suspend': tampilkan pesan akun disuspend, paksa logout
      ↓
Ambil resto_id dari dokumen USER
→ dipakai untuk filter order yang tampil di dashboard
      ↓
Masuk KaryawanHomePage
→ hanya menampilkan order dari resto_id yang terdaftar
→ tidak bisa akses halaman lain
```

---

## 5. Endpoint yang Perlu Ditambahkan ke Node.js

```
POST   /karyawan/tambah
       Body: { nama, email, password, resto_id }
       → Buat akun Firebase Auth + dokumen Firestore

PATCH  /karyawan/suspend/:uid
       → Disable Firebase Auth + update status Firestore

DELETE /karyawan/:uid
       → Hapus Firebase Auth + hapus dokumen Firestore
```

Semua endpoint wajib:
- Menyertakan `Authorization: Bearer {idToken}` di header
- Memverifikasi bahwa requester adalah owner yang valid
- Memverifikasi bahwa karyawan yang dikelola memang milik resto owner tersebut

---

## 6. Struktur Data Karyawan di Firestore

```
users/{uid} {
  id:           string   // UID Firebase Auth
  nama:         string   // nama karyawan
  email:        string   // email untuk login
  role:         string   // 'karyawan' (fixed)
  status:       string   // 'aktif' | 'suspend'
  resto_id:     string   // FK ke RESTO — terikat ke 1 resto
  poin_reward:  int      // selalu 0, tidak dipakai
  fcm_token:    string?  // untuk push notif order masuk
  foto_url:     string?  // null dulu sampai Storage tersedia
  url_whatsapp: string?  // null, tidak diperlukan karyawan
  created_at:   timestamp
}
```

---

## 7. Yang Perlu Disiapkan Sebelum Implementasi

### Sisi Backend (Node.js) — tanya ke tim backend:
```
□ Konfirmasi base URL backend (local / deployed)
□ Konfirmasi pola autentikasi yang sudah dipakai
  (Bearer token / API key / lainnya)
□ Konfirmasi pola endpoint yang sudah ada
  (untuk konsistensi penamaan)
□ Tambahkan 3 endpoint karyawan baru
□ Pastikan Firebase Admin SDK sudah ter-setup
```

### Sisi Flutter (Owner App):
```
□ Tambah package 'http' atau 'dio' di pubspec.yaml
  untuk HTTP request ke Node.js
□ Buat form tambah karyawan
□ Buat list karyawan (Firestore realtime stream)
□ Buat fungsi suspend & hapus karyawan
□ Tambahkan section Manajemen Karyawan
  di halaman Profil Owner
```

### Sisi AuthWrapper (Flutter):
```
□ Tambah case 'karyawan' di routing
□ Pastikan cek status 'suspend' jalan untuk role karyawan
□ Pastikan resto_id dibawa saat masuk KaryawanHomePage
```

---

## 8. Hal yang Perlu Diperhatikan

```
1. ID Token Firebase expired setiap 1 jam
   → Flutter harus selalu ambil token terbaru sebelum request
   → Pakai: await FirebaseAuth.instance.currentUser!.getIdToken()
   → Jangan simpan token lama di variabel

2. Password awal karyawan
   → Owner yang tentukan saat buat akun
   → Tidak ada fitur "lupa password" untuk karyawan
      (kalau lupa, owner reset dari dashboard manajemen karyawan)

3. Karyawan suspend vs hapus
   → Suspend: akun masih ada, hanya tidak bisa login
              bisa diaktifkan lagi kapan saja
   → Hapus: akun permanen terhapus dari Auth & Firestore
            tidak bisa dikembalikan

4. Satu karyawan hanya bisa terikat ke satu resto
   → Ditentukan saat akun dibuat via resto_id
   → Tidak bisa pindah resto tanpa hapus & buat akun baru
```

---

## 9. Ringkasan Pembagian Tugas

| Tugas | Dikerjakan oleh |
|---|---|
| Endpoint POST /karyawan/tambah | Tim Backend (Node.js) |
| Endpoint PATCH /karyawan/suspend | Tim Backend (Node.js) |
| Endpoint DELETE /karyawan/:uid | Tim Backend (Node.js) |
| Form tambah karyawan (Flutter) | Tim Flutter |
| List karyawan realtime (Flutter) | Tim Flutter |
| AuthWrapper — routing karyawan | Tim Flutter |
| KaryawanHomePage | Tim Flutter |
