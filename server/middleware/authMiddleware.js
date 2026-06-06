const admin = require('firebase-admin');

/**
 * Middleware untuk verifikasi ID Token Firebase.
 * 
 * Mengecek:
 * 1. Token valid (belum expired)
 * 2. User memiliki role 'owner' di Firestore
 * 3. Owner memiliki restaurant yang terdaftar
 * 
 * Meng-attach ke request:
 * - req.owner.uid     — UID Firebase Auth si owner
 * - req.owner.restoId — ID restaurant milik owner
 */
async function verifyOwner(req, res, next) {
  try {
    // 1. Ambil token dari header Authorization
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Token tidak ditemukan. Sertakan Authorization: Bearer {idToken}' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    // 2. Verifikasi token via Firebase Admin SDK
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const ownerUid = decodedToken.uid;

    // 3. Ambil dokumen user dari Firestore — pastikan role === 'owner'
    const userDoc = await admin.firestore().collection('users').doc(ownerUid).get();
    
    if (!userDoc.exists) {
      return res.status(403).json({ error: 'User tidak ditemukan di Firestore' });
    }

    const userData = userDoc.data();
    if (userData.role !== 'owner') {
      return res.status(403).json({ error: 'Akses ditolak. Hanya owner yang bisa mengelola karyawan.' });
    }

    // 4. Cari restaurant milik owner dari collection 'restaurants'
    const restoSnapshot = await admin.firestore()
      .collection('restaurants')
      .where('owner_id', '==', ownerUid)
      .limit(1)
      .get();

    if (restoSnapshot.empty) {
      return res.status(403).json({ error: 'Owner belum memiliki restaurant terdaftar.' });
    }

    const restoDoc = restoSnapshot.docs[0];

    // 5. Attach data owner ke request
    req.owner = {
      uid: ownerUid,
      restoId: restoDoc.id,
      restoData: restoDoc.data(),
    };

    next();
  } catch (error) {
    console.error('Auth Error:', error.message);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ error: 'Token sudah expired. Silakan refresh token.' });
    }
    if (error.code === 'auth/argument-error') {
      return res.status(401).json({ error: 'Format token tidak valid.' });
    }
    
    return res.status(401).json({ error: 'Gagal verifikasi token: ' + error.message });
  }
}

module.exports = { verifyOwner };
