const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// ─────────────────────────────────────────────
// Firebase Admin SDK Initialization
// ─────────────────────────────────────────────
// Download serviceAccountKey.json dari:
// Firebase Console → Project Settings → Service Accounts → Generate new private key
// Letakkan file tersebut di folder server/

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─────────────────────────────────────────────
// Express App Setup
// ─────────────────────────────────────────────
const app = express();
app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────
// Routes
// ─────────────────────────────────────────────
const karyawanRoutes = require('./routes/karyawan');
app.use('/karyawan', karyawanRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'CariMakan Backend Running' });
});

// ─────────────────────────────────────────────
// Start Server
// ─────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 CariMakan Backend berjalan di http://localhost:${PORT}`);
});
