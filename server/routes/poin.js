const admin = require('firebase-admin');
const db = admin.firestore();

// ─────────────────────────────────────────────
// Poin Queue Processor
//
// Pola Pending Action Queue:
//   Flutter menulis ke koleksi 'poin_queue' dengan status 'pending'
//   Node.js men-listen koleksi ini dan memproses setiap item
//   Tidak ada HTTP endpoint — semua digerakkan oleh Firestore listener
// ─────────────────────────────────────────────

function startPoinQueueListener() {
  console.log('🎯 Poin Queue Listener started...');

  const query = db.collection('poin_queue').where('status', '==', 'pending');

  query.onSnapshot(
    async (snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type === 'added' || change.type === 'modified') {
          const doc = change.doc;
          const data = doc.data();

          // Skip if somehow already processed (race condition guard)
          if (data.status !== 'pending') continue;

          try {
            await processQueueItem(doc.id, data);
          } catch (err) {
            console.error(`❌ Error processing poin_queue/${doc.id}:`, err.message);
            await db.collection('poin_queue').doc(doc.id).update({
              status: 'error',
              error_message: err.message,
              processed_at: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }
    },
    (err) => {
      console.error('Poin Queue Listener error:', err);
    }
  );
}

async function processQueueItem(docId, data) {
  const { tipe, user_id, order_id, jumlah, total_akhir } = data;

  if (!user_id || !tipe) {
    throw new Error('Data queue tidak valid: user_id atau tipe kosong');
  }

  const userRef = db.collection('users').doc(user_id);
  const queueRef = db.collection('poin_queue').doc(docId);

  if (tipe === 'earn') {
    // ── EARN: hitung poin dari total_akhir ──────────────────────
    if (total_akhir === undefined || total_akhir === null) {
      throw new Error('total_akhir diperlukan untuk tipe earn');
    }

    const poinDidapat = Math.floor(total_akhir * 0.5 / 100);

    if (poinDidapat <= 0) {
      // Tandai sebagai processed meski poin 0
      await queueRef.update({
        status: 'processed',
        poin_didapat: 0,
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new Error(`User ${user_id} tidak ditemukan`);

      const currentPoin = userSnap.data().poin_reward || 0;
      const newPoin = currentPoin + poinDidapat;

      // Update poin user
      tx.update(userRef, { poin_reward: newPoin });

      // Insert riwayat poin
      const riwayatRef = db.collection('reward_poin').doc();
      tx.set(riwayatRef, {
        user_id,
        order_id: order_id || null,
        jumlah_poin: poinDidapat,
        tipe: 'earn',
        keterangan: `Poin dari order${order_id ? ' #' + order_id.slice(-6).toUpperCase() : ''}`,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark queue processed
      tx.update(queueRef, {
        status: 'processed',
        poin_didapat: poinDidapat,
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ EARN: User ${user_id} mendapat ${poinDidapat} poin dari order ${order_id}`);

  } else if (tipe === 'redeem') {
    // ── REDEEM: kurangi poin ────────────────────────────────────
    const poinDigunakan = Math.abs(jumlah || 0);

    if (poinDigunakan <= 0) {
      await queueRef.update({
        status: 'processed',
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new Error(`User ${user_id} tidak ditemukan`);

      const currentPoin = userSnap.data().poin_reward || 0;

      // Validasi ulang (server-side validation)
      const actualPoinDigunakan = Math.min(poinDigunakan, currentPoin);
      if (actualPoinDigunakan <= 0) {
        // User tidak punya poin, skip redeem
        tx.update(queueRef, {
          status: 'processed',
          note: 'Poin tidak cukup, redeem dilewati',
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const newPoin = currentPoin - actualPoinDigunakan;

      tx.update(userRef, { poin_reward: newPoin });

      const riwayatRef = db.collection('reward_poin').doc();
      tx.set(riwayatRef, {
        user_id,
        order_id: order_id || null,
        jumlah_poin: -actualPoinDigunakan,
        tipe: 'redeem',
        keterangan: `Dipakai untuk order${order_id ? ' #' + order_id.slice(-6).toUpperCase() : ''}`,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(queueRef, {
        status: 'processed',
        poin_digunakan: actualPoinDigunakan,
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ REDEEM: User ${user_id} memakai ${poinDigunakan} poin untuk order ${order_id}`);

  } else if (tipe === 'rollback') {
    // ── ROLLBACK: kembalikan poin ───────────────────────────────
    const poinDikembalikan = Math.abs(jumlah || 0);

    if (poinDikembalikan <= 0) {
      await queueRef.update({
        status: 'processed',
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new Error(`User ${user_id} tidak ditemukan`);

      const currentPoin = userSnap.data().poin_reward || 0;
      const newPoin = currentPoin + poinDikembalikan;

      tx.update(userRef, { poin_reward: newPoin });

      const riwayatRef = db.collection('reward_poin').doc();
      tx.set(riwayatRef, {
        user_id,
        order_id: order_id || null,
        jumlah_poin: poinDikembalikan,
        tipe: 'refund',
        keterangan: `Rollback poin dari order${order_id ? ' #' + order_id.slice(-6).toUpperCase() : ''}`,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(queueRef, {
        status: 'processed',
        poin_dikembalikan: poinDikembalikan,
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ ROLLBACK: User ${user_id} mendapat kembali ${poinDikembalikan} poin dari order ${order_id}`);

  } else {
    throw new Error(`Tipe queue tidak dikenal: ${tipe}`);
  }
}

module.exports = { startPoinQueueListener };
