# 🍽️ CariMakan App

Aplikasi mobile berbasis Flutter untuk membantu pengguna melihat antrean restoran, melakukan pemesanan, dan meningkatkan efisiensi waktu saat dine-in maupun takeaway.

---

# 🚀 Tech Stack

* Flutter (Frontend)
* Firebase (Authentication & Firestore)
* Git & GitHub (Version Control)

---

# 📁 Struktur Kerja Tim

Setiap anggota tim WAJIB bekerja di branch masing-masing.

## 🌳 Branch utama:

* `main` → branch stabil (FINAL PROJECT)

## 🌿 Branch Peorang/Permodul:

Kerjain dulu permodul-perorang nanti diakhir project baru finalisasi

---

# ⚠️ RULE WAJIB (JANGAN DILANGGAR)

❌ DILARANG push langsung ke `main`
❌ DILARANG kerja di branch orang lain
❌ DILARANG merge tanpa Pull Request

✅ WAJIB pakai branch sendiri
✅ WAJIB Pull Request sebelum merge
✅ WAJIB update dari main sebelum mulai kerja

---

# 🧑‍💻 Cara Setup Project

```bash
git clone https://github.com/Zuuru/CariMakan.git
cd CariMakan
flutter pub get
flutter run
```

---

# 🌿 Cara Kerja (Workflow)

## 1. Ambil update terbaru dari main

```bash
git checkout main
git pull origin main
```

## 2. Buat branch baru

```bash
git checkout -b feature/nama-fitur
```

Contoh:

```bash
git checkout -b feature/auth
```

---

## 3. Kerja & commit

```bash
git add .
git commit -m "menambahkan fitur login"
```

---

## 4. Push ke GitHub

```bash
git push -u origin feature/nama-fitur
```

---

## 5. Buat Pull Request (PR)

* Buka GitHub repo
* Klik **Compare & pull request**
* Pilih:

  * base: `main`
  * compare: branch kamu
* Klik **Create Pull Request**

---

## 6. Merge ke main

* Tunggu review (kalau ada)
* Klik **Merge Pull Request**

---

# 🔄 Update Branch (WAJIB sebelum kerja)

```bash
git checkout main
git pull origin main
git checkout feature/nama-fitur
git merge main
```

---

# ⚠️ Mengatasi Conflict

Jika terjadi conflict:

* Jangan panik 😄
* Perbaiki file yang conflict
* Lalu:

```bash
git add .
git commit -m "fix conflict"
```

---

# 📌 Pembagian Tugas (Contoh)

| Nama | Tugas      | Branch           |
| ---- | ---------- | ---------------- |
| A    | Login/Auth | feature/auth     |
| B    | UI         | feature/ui       |
| C    | Order      | feature/order    |
| D    | Database   | feature/database |

---

# 🔥 Tips Biar Lancar

* Commit kecil tapi sering
* Jangan nunggu selesai baru push
* Selalu pull sebelum mulai kerja
* Gunakan nama branch yang jelas

---

# 🎯 Goal Project

* User bisa login/register
* Melihat restoran & menu
* Melakukan pemesanan
* Melihat antrean realtime

---

# 💪 Semangat Tim!

Kerja rapi = project cepat selesai 🚀
