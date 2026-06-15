const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function check() {
  console.log('--- RESTAURANTS ---');
  const restosSnap = await db.collection('restaurants').get();
  for (const doc of restosSnap.docs) {
    console.log(doc.id, '=>', doc.data());
  }

  console.log('--- REVIEWED ORDERS ---');
  const ordersSnap = await db.collection('orders').where('sudah_direview', '==', true).get();
  for (const doc of ordersSnap.docs) {
    console.log(doc.id, '=>', doc.data());
  }
}

check().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
