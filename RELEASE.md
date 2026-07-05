# Makaan Production Release Guide

## Firebase project
The included Android Firebase configuration is installed at:

```text
android/app/google-services.json
```

It targets Android package:

```text
com.example.makaan
```

Do not change `applicationId` unless you also create a matching Android app in Firebase Console and replace `google-services.json`.

## Required Firebase services
Enable these services in Firebase Console before production testing:

1. Authentication -> Phone provider.
2. Cloud Firestore.
3. Firebase Storage.
4. Firebase Cloud Messaging.

## Install dependencies

```bash
flutter pub get
```

## Run QA checks

```bash
flutter analyze
flutter test
```

## Run locally

```bash
flutter run
```

## Android signing
Copy the example file:

```bash
cp android/key.properties.example android/key.properties
```

Create a release keystore, then update:

```text
storePassword
keyPassword
keyAlias
storeFile
```

## Build APK

```bash
flutter build apk --release
```

## Build AAB for Google Play

```bash
flutter build appbundle --release
```

## Firebase rules
Review and publish:

```text
../database/firebase_phase12_firestore_rules.rules
../database/firebase_phase12_storage_rules.rules
```

## Push notifications
The app registers FCM tokens in `push_tokens` and queues notification intents in `push_notification_queue`. A Firebase Cloud Function or server using Firebase Admin SDK is required to deliver queued notifications securely.
