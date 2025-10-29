const admin = require('firebase-admin');
const fs = require('fs');

const serviceAccount = {
  "type": "service_account",
  "project_id": "plp-ai-tutor",
  "private_key_id": "YOUR_PRIVATE_KEY_ID",
  "private_key": "YOUR_PRIVATE_KEY",
  "client_email": "YOUR_CLIENT_EMAIL",
  "client_id": "YOUR_CLIENT_ID",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "YOUR_CLIENT_CERT_URL"
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://plp-ai-tutor.firebaseio.com"
});

const db = admin.firestore();

const topics = JSON.parse(fs.readFileSync('./topics_data.json', 'utf8'));

async function uploadTopics() {
  console.log(`Starting to upload ${topics.length} topics...`);

  let successCount = 0;
  let failCount = 0;

  for (const topic of topics) {
    try {
      await db.collection('topics').doc(topic.id).set({
        ...topic,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      successCount++;
      console.log(`✓ Uploaded: ${topic.title}`);
    } catch (error) {
      failCount++;
      console.error(`✗ Failed to upload ${topic.title}:`, error.message);
    }
  }

  console.log('\n=== Upload Summary ===');
  console.log(`Total topics: ${topics.length}`);
  console.log(`Successfully uploaded: ${successCount}`);
  console.log(`Failed: ${failCount}`);
  console.log('======================\n');

  console.log('Upload process completed!');
  process.exit(0);
}

uploadTopics().catch(error => {
  console.error('Error uploading topics:', error);
  process.exit(1);
});
