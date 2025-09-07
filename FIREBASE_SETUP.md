# Firebase Setup Instructions

This document provides step-by-step instructions for setting up Firebase with your PureMetrics app.

## Prerequisites

1. A Google account
2. Xcode installed
3. iOS device or simulator for testing

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `PureMetrics` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

## Step 2: Add iOS App to Firebase Project

1. In the Firebase Console, click "Add app" and select iOS
2. Enter your iOS bundle ID: `com.yourcompany.PureMetrics`
3. Enter app nickname: `PureMetrics`
4. Enter App Store ID (optional, leave blank for now)
5. Click "Register app"

## Step 3: Download Configuration File

1. Download the `GoogleService-Info.plist` file
2. Replace the template file in your project root with the downloaded file
3. Make sure the file is added to your Xcode project target

## Step 4: Enable Firebase Services

### Authentication
1. In Firebase Console, go to "Authentication" > "Sign-in method"
2. Enable "Email/Password" provider
3. Optionally enable other providers (Google, Apple, etc.)

### Firestore Database
1. Go to "Firestore Database" > "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location for your database
4. Click "Done"

### Storage
1. Go to "Storage" > "Get started"
2. Choose "Start in test mode" (for development)
3. Select a location for your storage bucket
4. Click "Done"

## Step 5: Update Security Rules (Important!)

### Firestore Rules
Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Storage Rules
Replace the default rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only access their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Add Firebase Dependencies to Xcode

1. Open your Xcode project
2. Go to File > Add Package Dependencies
3. Enter: `https://github.com/firebase/firebase-ios-sdk.git`
4. Select version: "Up to Next Major Version" with "10.0.0"
5. Add these products to your target:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics

## Step 7: Update Bundle Identifier

1. In Xcode, select your project
2. Go to "Signing & Capabilities"
3. Update the Bundle Identifier to match what you used in Firebase Console
4. Make sure "Automatically manage signing" is enabled

## Step 8: Test the Integration

1. Build and run your app
2. Try creating an account
3. Check Firebase Console to see if data appears
4. Test the authentication flow

## Features Included

### Authentication
- Email/password sign up and sign in
- Password reset functionality
- User profile management
- Sign out functionality

### Firestore Database
- User-specific data storage
- Blood pressure sessions sync
- Fitness sessions sync
- User profile storage
- Real-time data synchronization

### Firebase Storage
- Profile image upload
- Workout image upload
- Data backup creation
- File management and cleanup

### Data Models
- `UserProfile` - User information and preferences
- `DataBackup` - Complete data backup structure
- Automatic data encoding/decoding for Firestore

## Security Considerations

1. **Never commit your `GoogleService-Info.plist` to version control**
2. **Use proper Firestore security rules** (provided above)
3. **Use proper Storage security rules** (provided above)
4. **Enable App Check** for production (optional but recommended)
5. **Monitor usage** in Firebase Console

## Troubleshooting

### Common Issues

1. **"No such module 'FirebaseAuth'"**
   - Make sure you added the Firebase packages correctly
   - Clean build folder (Cmd+Shift+K) and rebuild

2. **"GoogleService-Info.plist not found"**
   - Make sure the file is in your project root
   - Make sure it's added to your Xcode target

3. **Authentication not working**
   - Check that Email/Password is enabled in Firebase Console
   - Verify your bundle ID matches Firebase configuration

4. **Database permission denied**
   - Check your Firestore security rules
   - Make sure user is authenticated before accessing data

### Getting Help

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios)
- [Firebase iOS SDK GitHub](https://github.com/firebase/firebase-ios-sdk)
- [Firebase Console](https://console.firebase.google.com/)

## Next Steps

1. Set up push notifications (optional)
2. Add analytics tracking (optional)
3. Set up App Check for security (recommended for production)
4. Configure backup and restore functionality
5. Add offline support with Firestore offline persistence
