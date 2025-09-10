#!/bin/bash

# Deploy Firestore security rules
echo "Deploying Firestore security rules..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Deploy the rules
firebase deploy --only firestore:rules

echo "Firestore rules deployed successfully!"
