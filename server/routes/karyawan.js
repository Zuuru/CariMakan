const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { verifyOwner } = require('../middleware/authMiddleware');

const db = admin.firestore();

// ─────────────────────────────────────────────
// POST /karyawan/tambah
// Body: { nama, email, password }
// → Buat akun Firebase Auth + dokumen Firestore
// ─────────────────────────────────────────────
router.post('/tambah', verifyOwner, async (req, res) => {
  try {
    const { nama, email, password } = req.body;
    const { restoId } = req.owner;

    // Validasi input
    if (!nama || !email || !password) {
      return res.status(400).json({ error: 'Nama, email, dan password wajib diisi.' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password minimal 6 karakter.' });
    }

    // Validasi format email sederhana
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Format email tidak valid.' });
    }

    // 1. Buat akun di Firebase Auth via Admin SDK
    //    Ini TIDAK mengganggu sesi login owner di Flutter
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: nama,
    });

    // 2. Tulis dokumen user ke Firestore
    const userData = {
      id: userRecord.uid,
      nama: nama,
      email: email,
      role: 'karyawan',
      status: 'aktif',
      resto_id: restoId,
      poin_reward: 0,
      fcm_token: null,
      foto_url: null,
      url_whatsapp: null,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(userRecord.uid).set(userData);

    // 3. Response sukses
    return res.status(201).json({
      message: 'Akun karyawan berhasil dibuat.',
      data: {
        uid: userRecord.uid,
        nama: nama,
        email: email,
        resto_id: restoId,
        status: 'aktif',
      },
    });
  } catch (error) {
    console.error('Error tambah karyawan:', error.message);

    // Handle specific Firebase Auth errors
    if (error.code === 'auth/email-already-exists') {
      return res.status(409).json({ error: 'Email sudah terdaftar. Gunakan email lain.' });
    }
    if (error.code === 'auth/invalid-email') {
      return res.status(400).json({ error: 'Format email tidak valid.' });
    }
    if (error.code === 'auth/weak-password') {
      return res.status(400).json({ error: 'Password terlalu lemah.' });
    }

    return res.status(500).json({ error: 'Gagal membuat akun karyawan: ' + error.message });
  }
});

// ─────────────────────────────────────────────
// PATCH /karyawan/suspend/:uid
// → Disable/Enable Firebase Auth + update status Firestore
// Jika status saat ini 'aktif' → suspend
// Jika status saat ini 'suspend' → aktifkan kembali
// ─────────────────────────────────────────────
router.patch('/suspend/:uid', verifyOwner, async (req, res) => {
  try {
    const { uid } = req.params;
    const { restoId } = req.owner;

    // 1. Ambil dokumen karyawan — pastikan milik resto owner ini
    const karyawanDoc = await db.collection('users').doc(uid).get();

    if (!karyawanDoc.exists) {
      return res.status(404).json({ error: 'Karyawan tidak ditemukan.' });
    }

    const karyawanData = karyawanDoc.data();

    if (karyawanData.role !== 'karyawan') {
      return res.status(400).json({ error: 'User ini bukan karyawan.' });
    }

    if (karyawanData.resto_id !== restoId) {
      return res.status(403).json({ error: 'Karyawan ini bukan milik resto Anda.' });
    }

    // 2. Toggle status
    const isCurrentlyActive = karyawanData.status === 'aktif';
    const newStatus = isCurrentlyActive ? 'suspend' : 'aktif';

    // 3. Update Firebase Auth (disable/enable)
    await admin.auth().updateUser(uid, {
      disabled: isCurrentlyActive, // true jika di-suspend, false jika diaktifkan
    });

    // 4. Update Firestore
    await db.collection('users').doc(uid).update({
      status: newStatus,
    });

    return res.status(200).json({
      message: isCurrentlyActive
        ? 'Karyawan berhasil di-suspend.'
        : 'Karyawan berhasil diaktifkan kembali.',
      data: {
        uid: uid,
        status: newStatus,
      },
    });
  } catch (error) {
    console.error('Error suspend karyawan:', error.message);
    return res.status(500).json({ error: 'Gagal update status karyawan: ' + error.message });
  }
});

// ─────────────────────────────────────────────
// DELETE /karyawan/:uid
// → Hapus Firebase Auth + hapus dokumen Firestore
// ─────────────────────────────────────────────
router.delete('/:uid', verifyOwner, async (req, res) => {
  try {
    const { uid } = req.params;
    const { restoId } = req.owner;

    // 1. Ambil dokumen karyawan — pastikan milik resto owner ini
    const karyawanDoc = await db.collection('users').doc(uid).get();

    if (!karyawanDoc.exists) {
      return res.status(404).json({ error: 'Karyawan tidak ditemukan.' });
    }

    const karyawanData = karyawanDoc.data();

    if (karyawanData.role !== 'karyawan') {
      return res.status(400).json({ error: 'User ini bukan karyawan.' });
    }

    if (karyawanData.resto_id !== restoId) {
      return res.status(403).json({ error: 'Karyawan ini bukan milik resto Anda.' });
    }

    // 2. Hapus akun di Firebase Auth
    await admin.auth().deleteUser(uid);

    // 3. Hapus dokumen di Firestore
    await db.collection('users').doc(uid).delete();

    return res.status(200).json({
      message: 'Akun karyawan berhasil dihapus.',
      data: { uid: uid },
    });
  } catch (error) {
    console.error('Error hapus karyawan:', error.message);

    if (error.code === 'auth/user-not-found') {
      // User sudah tidak ada di Auth, tetap hapus Firestore doc
      await db.collection('users').doc(req.params.uid).delete();
      return res.status(200).json({
        message: 'Dokumen karyawan berhasil dihapus (akun Auth sudah tidak ada).',
        data: { uid: req.params.uid },
      });
    }

    return res.status(500).json({ error: 'Gagal menghapus karyawan: ' + error.message });
  }
});

module.exports = router;
