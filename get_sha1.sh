#!/bin/bash

# Script to get SHA-1 fingerprint for Google Sign-In setup

echo "========================================="
echo "Getting SHA-1 Fingerprint for Debug Build"
echo "========================================="
echo ""

cd android

echo "Running gradlew signingReport..."
echo ""

./gradlew signingReport | grep -A 10 "Variant: debug" | grep SHA1
echo ""

echo "========================================="
echo "Getting SHA-1 Fingerprint for Release Build"
echo "========================================="
echo ""

./gradlew signingReport | grep -A 10 "Variant: release" | grep SHA1

echo ""
echo "========================================="
echo "Copy the SHA-1 values above and add them to:"
echo "Google Cloud Console → Credentials → Android OAuth Client"
echo "OR"
echo "Firebase Console → Project Settings → Your Apps → Add Fingerprint"
echo "========================================="
