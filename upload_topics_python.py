#!/usr/bin/env python3
"""
Upload topics to Firebase Firestore using Python
Requires: pip install firebase-admin
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore

def main():
    # Initialize Firebase Admin SDK
    # Download your service account key from Firebase Console
    # and save it as 'serviceAccountKey.json'
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)

    db = firestore.client()

    # Load topics data
    with open('topics_data.json', 'r') as f:
        topics = json.load(f)

    print(f'Starting to upload {len(topics)} topics...')

    success_count = 0
    fail_count = 0

    for topic in topics:
        try:
            # Add server timestamp
            topic_data = topic.copy()
            topic_data['createdAt'] = firestore.SERVER_TIMESTAMP

            # Upload to Firestore
            db.collection('topics').document(topic['id']).set(topic_data)
            success_count += 1
            print(f"✓ Uploaded: {topic['title']}")
        except Exception as e:
            fail_count += 1
            print(f"✗ Failed to upload {topic['title']}: {str(e)}")

    print('\n=== Upload Summary ===')
    print(f'Total topics: {len(topics)}')
    print(f'Successfully uploaded: {success_count}')
    print(f'Failed: {fail_count}')
    print('======================\n')
    print('Upload process completed!')

if __name__ == '__main__':
    main()
