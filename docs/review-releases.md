# Review releases

Upload review builds to Firebase App Distribution for project `tanago-77c59`.
Use the existing tester group **TagaGOTester**, alias **tagagotester** (confirmed by the user on 2026-10-01), rather than an individual tester email.

```sh
flutter analyze
flutter test
flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:715957827608:android:8f386a393733f78ebaab6d \
  --project tanago-77c59 \
  --groups tagagotester \
  --release-notes-file /path/to/release-notes.txt
```

Increment the version/build number before building. Include concise Japanese release notes with the changes and review points. When modifying Firestore fields, test and deploy the matching rules before distributing. Confirm successful group distribution and share the tester release URL.
