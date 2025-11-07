// Environment variables for the app
// Note: In production, these should be loaded from a .env file using envied package
class Env {
  // API Configuration
  static const String apiBaseUrl = 'http://3.220.103.255:8080';
  static const String apiVersion = '/api/v1';

  // Google Sign-In Configuration
  static const String googleClientId =
      '234604531809-1vmkuskqcdl5hgk177m5fs2bkfj6kd0d.apps.googleusercontent.com';
  static const String googleServerClientId =
      '234604531809-8jgq1eiv5fouiik1dn1sd5hoio5297ct.apps.googleusercontent.com';

  // RevenueCat Configuration
  static const String revenueCatPlayStore = 'your-revenue-cat-play-store-key';
  static const String revenueCatAppStore = 'your-revenue-cat-app-store-key';
}
