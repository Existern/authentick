// Environment variables for the app
// These are hardcoded for development. For production, consider using the envied package
// to generate this file from environment variables at build time.
class Env {
  // API Configuration
  static const String apiBaseUrl = 'http://34.227.101.233:8092';
  static const String apiVersion = '/api/v1';

  // Google Sign-In Configuration
  static const String googleClientId =
      '234604531809-1vmkuskqcdl5hgk177m5fs2bkfj6kd0d.apps.googleusercontent.com';
  static const String googleServerClientId =
      '234604531809-8jgq1eiv5fouiik1dn1sd5hoio5297ct.apps.googleusercontent.com';

  // RevenueCat Configuration
  static const String revenueCatPlayStore = 'your-revenue-cat-play-store-key';
  static const String revenueCatAppStore = 'your-revenue-cat-app-store-key';

  // Sentry Configuration
  static const String sentryDsn =
      'https://6d54542a200f342206cadfb1efd403c6@o4510551334715392.ingest.de.sentry.io/4510551338123344';

  // Clarity Configuration
  static const String clarityProjectId = 'usghw4nu8v';
}
