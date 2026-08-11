class GooglePlacesConstants {
  // Injected at build time via:
  //   flutter run --dart-define-from-file=secrets.json
  //   flutter build apk --release --dart-define-from-file=secrets.json
  //   flutter build appbundle --release --dart-define-from-file=secrets.json
  //
  // secrets.json lives at project root, is git-ignored, never committed.
  // If this ever prints empty, you forgot the --dart-define-from-file flag.
  //
  // Production security note: restrict this key in Google Cloud Console to
  // your Android package name + SHA-1 fingerprint (and iOS bundle ID once
  // live), and restrict its API list to only "Maps SDK for Android/iOS" +
  // "Places API (New)". That prevents anyone who extracts the key from your
  // APK/IPA from using it for anything else on your billing account.
  static const String apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static const String autocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  static String placeDetailsUrl(String placeId) => 'https://places.googleapis.com/v1/places/$placeId';
}