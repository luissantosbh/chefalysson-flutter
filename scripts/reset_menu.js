// scripts/reset_menu.js
// Apaga todos os documentos de menu_items para forçar re-seed com o cardápio novo.
// Uso: node scripts/reset_menu.js

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

// Caminho para o arquivo de credenciais do Firebase Admin
const serviceAccount = require(path.join(__dirname, '../ios/Runner/GoogleService-Info-admin.json'));

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();

async function deleteCollection(collectionPath) {
  const ref = db.collection(collectionPath);
  const snapshot = await ref.get();
  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  console.log(`✅ ${snapshot.size} documentos apagados de '${collectionPath}'`);
}

deleteCollection('menu_items').catch(console.error);
