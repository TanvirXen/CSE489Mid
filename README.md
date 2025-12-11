# Bangladesh Landmark Vault

## App Summary
Bangladesh Landmark Vault is a Flutter application that lets travelers and researchers catalog important landmarks around the country. Authenticated users can browse a map-based overview, review existing records, and add new entries with metadata and photos stored via the provided API.

## Feature List
- Email/password authentication powered by Firebase Auth.
- Overview, Records, and New Entry tabs with state managed via Provider controllers.
- Landmark CRUD backed by the `LandmarkApi`, including image uploads with media-type sniffing and filename sanitization.
- Dark/light theme toggle and responsive layouts that work across mobile and desktop targets.

## Setup Instructions
1. **Install prerequisites**: Flutter 3.10+, Dart SDK, and platform toolchains for your target OSes.
2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Firebase**:
   - Run `flutterfire configure` (recommended) to generate `lib/firebase_options.dart`, or manually place `google-services.json` (Android) / `GoogleService-Info.plist` (iOS & macOS) and call `Firebase.initializeApp`.
   - Ensure email/password auth is enabled in the Firebase console.
4. **Provide API access**: The landmark API endpoint is hardcoded in `lib/services/landmark_api.dart`. Update the base URL or credentials if your environment differs.
5. **Run the app**:
   ```bash
   flutter run
   ```

## Known Limitations
- **Image update workflow**: The remote API cannot replace an existing image in place. To work around this, the app duplicates the entry with the new photo, deletes the previous entry, and assigns the new ID back to the draft. This can produce brief record churn and may fail if deletion is blocked.
