const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

const restaurants = [
  {
    nama: 'Ideologist Coffee And Social Space',
    lokasi_alamat: 'Jl. Baskoro No.38, Tembalang, Kec. Tembalang, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0485, 110.4395),
    avg_rating: 4.9,
    foto_profil: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Cafe',
    total_review: 4
  },
  {
    nama: 'Burjo Parjo Sipodang',
    lokasi_alamat: 'Jl. Sipodang, Tembalang, Kec. Tembalang, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0512, 110.4368),
    avg_rating: 4.7,
    foto_profil: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Makanan Berat',
    total_review: 8
  },
  {
    nama: 'Warmindo Berkah',
    lokasi_alamat: 'Jl. Prof. Soedarto, Tembalang, Kec. Tembalang, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0501, 110.4412),
    avg_rating: 4.5,
    foto_profil: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&auto=format&fit=crop&q=60',
    status: 'nonaktif',
    category: 'Makanan Berat',
    total_review: 2
  },
  {
    nama: 'McDonald\'s Tembalang',
    lokasi_alamat: 'Jl. Ngesrep Timur V No.25, Sumurboto, Kec. Banyumanik, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0450, 110.4420),
    avg_rating: 4.6,
    foto_profil: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Fastfood',
    total_review: 15
  },
  {
    nama: 'Kopi Kenangan Tembalang',
    lokasi_alamat: 'Jl. Prof. Soedarto No.12, Tembalang, Kec. Tembalang, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0490, 110.4390),
    avg_rating: 4.8,
    foto_profil: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Cafe',
    total_review: 12
  },
  {
    nama: 'Mie Gacoan Tembalang',
    lokasi_alamat: 'Jl. Kompol Maksum, Tembalang, Kec. Tembalang, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0480, 110.4410),
    avg_rating: 4.7,
    foto_profil: 'https://images.unsplash.com/photo-1552611052-33e04de081de?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Makanan Berat',
    total_review: 24
  },
  {
    nama: 'KFC Tembalang',
    lokasi_alamat: 'Jl. Setiabudi No.110, Srondol Kulon, Kec. Banyumanik, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0460, 110.4400),
    avg_rating: 4.5,
    foto_profil: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Fastfood',
    total_review: 18
  },
  {
    nama: 'Sweet & Chill Dessert',
    lokasi_alamat: 'Jl. Banjarsari No.45, Tembalang, Kec. Tembalang, Kota Semarang',
    lokasi: new admin.firestore.GeoPoint(-7.0525, 110.4385),
    avg_rating: 4.8,
    foto_profil: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60',
    status: 'aktif',
    category: 'Dessert',
    total_review: 7
  }
];

async function seed() {
  console.log('⏳ Seeding restaurants data into Firestore...');
  const collectionRef = db.collection('restaurants');
  
  for (const resto of restaurants) {
    try {
      // Find if restaurant already exists to avoid duplicates (optional, or just add new ones)
      const snapshot = await collectionRef.where('nama', '==', resto.nama).get();
      if (snapshot.empty) {
        await collectionRef.add(resto);
        console.log(`✅ Added: ${resto.nama}`);
      } else {
        console.log(`ℹ️ Already exists, skipping: ${resto.nama}`);
      }
    } catch (e) {
      console.error(`❌ Error adding ${resto.nama}:`, e);
    }
  }
  console.log('🏁 Seeding finished!');
  process.exit(0);
}

seed();
