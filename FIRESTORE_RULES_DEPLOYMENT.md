# Firestore Rules Deployment Instructions

## Problem
The app is getting "Missing or insufficient permissions" errors when trying to read from the `health_data` collections because the Firestore security rules don't allow access to root-level collections.

## Solution
The `firestore.rules` file has been updated to allow access to both:
1. User-specific collections: `/users/{userId}/health_data/...`
2. Root-level collections: `/health_data/...`

## How to Deploy the Rules

### Option 1: Using Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to "Firestore Database" → "Rules" tab
4. Replace the existing rules with the content from `firestore.rules`
5. Click "Publish"

### Option 2: Using Firebase CLI
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize project: `firebase init firestore`
4. Deploy: `firebase deploy --only firestore:rules`

### Option 3: Temporary Testing (Less Secure)
For immediate testing, you can temporarily use these rules (NOT for production):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## What the Updated Rules Do
- Allow authenticated users to read/write their own data under `/users/{userId}/`
- Allow authenticated users to read/write data in root-level `/health_data/` collections
- Maintain security by requiring authentication for all operations

## After Deployment
Once the rules are deployed, the app should be able to:
- Load data from both user-specific and root-level collections
- Display your existing data in the trends view
- No longer show "Missing or insufficient permissions" errors
