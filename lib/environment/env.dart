// Environment variables for the app
// These are hardcoded for development. For production, consider using the envied package
// to generate this file from environment variables at build time.
class Env {
  // Google Sign-In Configuration
  static const String googleClientId =
      '234604531809-1vmkuskqcdl5hgk177m5fs2bkfj6kd0d.apps.googleusercontent.com';
  static const String googleServerClientId =
      '234604531809-8jgq1eiv5fouiik1dn1sd5hoio5297ct.apps.googleusercontent.com';

  // RevenueCat Configuration
  static const String revenueCatPlayStore = 'your-revenue-cat-play-store-key';
  static const String revenueCatAppStore = 'your-revenue-cat-app-store-key';
}
