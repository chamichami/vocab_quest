# Vocab Quest: connecting Firebase and Cloudinary

## 1. Firebase (Auth + Firestore)

The Flutter app is connected to Firebase project `vocab-quest-d8cee`.
`lib/firebase_options.dart` has been generated for Android, iOS, and web.
The registered app IDs use Android package `com.example.vocab_quest` and iOS
bundle ID `com.example.vocabQuest`.

Email/Password and Google providers are enabled, the Android service file has
been refreshed with the Google OAuth clients, and the default Firestore
database and rules are set up. The published Firestore rules are:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    // Player profiles. Signed-in players can read them (needed for ranking).
    match /users/{uid} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == uid;
    }

    // username -> email lookup, so players can log in with a username.
    match /usernames/{name} {
      allow get: if true;
      allow create: if request.auth != null
                    && request.resource.data.uid == request.auth.uid;
    }
  }
}
```

1. **Android + Google sign-in:** add your SHA-1 key in Project settings ->
   your Android app. Get it with `cd android; .\gradlew signingReport` (use
   the debug key for testing, and your release key later).
2. Android release builds: add
   `<uses-permission android:name="android.permission.INTERNET"/>` to
   `android/app/src/main/AndroidManifest.xml`. Firebase needs `minSdk 23` or
   higher.
3. iOS: add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist` (needed
   to pick a profile picture).

To regenerate the Firebase config after changing registered apps or platforms,
run `flutterfire configure --project=vocab-quest-d8cee --platforms=android,ios,web`.

## 2. Cloudinary (profile pictures)
1. In Cloudinary, open **Settings -> Upload -> Upload presets -> Add upload
   preset**.
2. Set **Signing mode: Unsigned**, give it a name, and save. The preset should
   allow image uploads.
3. In the Cloudinary dashboard, copy your **Cloud name** (not your API key).
4. Open `lib/app_config.dart` and replace the two placeholder values with:
   - `cloudinaryCloudName`: the cloud name shown at the top-left of the dashboard
   - `cloudinaryUploadPreset`: the preset name from step 2
5. Do **not** put your API key or API secret in the app. The cloud name and
   unsigned preset name are all the app needs. Restart/rebuild the app after
   changing these values. Photo upload is unavailable until both are filled.

## 3. Your images
Replace these image files in `lib/assets/images/`, keeping the file names:
- `lib/assets/images/ocean.png`
- `lib/assets/images/fire.png`
- `lib/assets/images/forest.png`
- optional: add `lib/assets/images/logo.png` (shown on the login screen; a
  designed placeholder appears until you add it)
- optional: swap `assets/audio/bgm.wav` for your own music (same name, or edit `_track` in `settings_service.dart`)

To add a level, add one entry in `lib/levels.dart` and a matching image under
`lib/assets/images/`.

## Notes
- Login accepts a username or an email. The username lookup makes the email for a username readable by anyone who knows that username. If that matters for your project, make the login field email-only.
- Scores are saved by the app itself, so a technical user could edit their own score. That's fine for a class project; a public leaderboard would need a Cloud Function to validate scores.
