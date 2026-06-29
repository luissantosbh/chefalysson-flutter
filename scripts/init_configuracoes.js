// scripts/init_configuracoes.js
// Cria o documento configuracoes/app no Firestore com os campos de manutenção.
// Uso: node scripts/init_configuracoes.js

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../ios/Runner/GoogleService-Info-admin.json'));

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();

async function main() {
  const ref = db.collection('settings').doc('app');
  const snap = await ref.get();

  if (snap.exists) {
    console.log('Documento configuracoes/app já existe:', snap.data());
    console.log('Nenhuma alteração feita.');
    return;
  }

  await ref.set({
    emManutencaoIOS: false,
    emManutencaoAndroid: false,
  });

  console.log('Documento configuracoes/app criado com sucesso.');
}

main().catch(console.error);
