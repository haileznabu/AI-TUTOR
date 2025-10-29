#!/bin/bash
# Upload topics to Firebase Firestore using REST API
# Make sure to replace YOUR_API_KEY with your actual Firebase API key

API_KEY="AIzaSyBUK7Tqltu29luyvRM9s-rxLXrfg6pSloA"
PROJECT_ID="plp-ai-tutor"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/topics"

echo "Starting to upload topics to Firestore..."

# Topic 1
curl -X PATCH "${BASE_URL}/1?key=${API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "id": {"stringValue": "1"},
      "title": {"stringValue": "Flutter Basics"},
      "description": {"stringValue": "Learn the fundamentals of Flutter development"},
      "category": {"stringValue": "Programming"},
      "iconCodePoint": {"integerValue": "58156"},
      "iconFontFamily": {"stringValue": "MaterialIcons"},
      "estimatedMinutes": {"integerValue": "30"},
      "difficulty": {"stringValue": "Beginner"}
    }
  }'
echo -e "\n✓ Uploaded: Flutter Basics"

# Topic 2
curl -X PATCH "${BASE_URL}/2?key=${API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "id": {"stringValue": "2"},
      "title": {"stringValue": "State Management"},
      "description": {"stringValue": "Master state management with Provider and Riverpod"},
      "category": {"stringValue": "Programming"},
      "iconCodePoint": {"integerValue": "59577"},
      "iconFontFamily": {"stringValue": "MaterialIcons"},
      "estimatedMinutes": {"integerValue": "45"},
      "difficulty": {"stringValue": "Intermediate"}
    }
  }'
echo -e "\n✓ Uploaded: State Management"

# Topic 3
curl -X PATCH "${BASE_URL}/3?key=${API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "id": {"stringValue": "3"},
      "title": {"stringValue": "REST APIs"},
      "description": {"stringValue": "Understanding and working with REST APIs"},
      "category": {"stringValue": "Programming"},
      "iconCodePoint": {"integerValue": "58045"},
      "iconFontFamily": {"stringValue": "MaterialIcons"},
      "estimatedMinutes": {"integerValue": "40"},
      "difficulty": {"stringValue": "Intermediate"}
    }
  }'
echo -e "\n✓ Uploaded: REST APIs"

# Add remaining topics here...
# For all 55 topics, follow the same pattern

echo -e "\n=== Upload Summary ==="
echo "Check Firebase Console to verify uploaded topics"
echo "======================"
