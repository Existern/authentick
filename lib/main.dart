import 'dart:io';

import 'package:clarity_flutter/clarity_flutter.dart' as clarity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'constants/constants.dart';
import 'environment/env.dart';
import 'extensions/build_context_extension.dart';
import 'features/common/ui/providers/app_theme_mode_provider.dart';
import 'features/common/ui/providers/provider_invalidator.dart';
import 'features/common/ui/widgets/offline_container.dart';
import 'features/common/service/session_manager.dart';
import 'routing/router.dart';
import 'services/sentry_service.dart';
import 'utils/provider_observer.dart';

Future<void> initPlatformState() async {
  try {
    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(
      Platform.isIOS ? Env.revenueCatAppStore : Env.revenueCatPlayStore,
    );
    await Purchases.configure(configuration);
  } on PlatformException catch (e) {
    debugPrint('${Constants.tag} [initPlatformState] Error: ${e.message}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Localization
  await EasyLocalization.ensureInitialized();

  /// Google Font
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  /// Initialize Sentry before running the app
  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
      options.enableAutoSessionTracking = true;
      options.captureFailedRequests = true;
      options.sendDefaultPii = false;
      options.attachScreenshot = true;
      options.screenshotQuality = SentryScreenshotQuality.medium;
      options.attachViewHierarchy = true;
      options.enableAutoPerformanceTracing = true;
      options.debug = false; // Disable console logs, keep cloud tracking
      options.attachStacktrace = true;
      options.sendClientReports = true;

      // Disable user interaction tracking to reduce noisy breadcrumb logs
      options.enableUserInteractionTracing = false;
      options.enableUserInteractionBreadcrumbs = false;

      // Filter events - allow in debug mode for testing
      options.beforeSend = (event, hint) {
        // Send all events including debug mode
        return event;
      };
    },
    appRunner: () async {
      /// Firebase
      // await Firebase.initializeApp(
      //     // options: DefaultFirebaseOptions.currentPlatform,
      //     );
      // await FirebaseAnalytics.instance.logAppOpen();
      // FlutterError.onError = (errorDetails) {
      //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      // };
      // PlatformDispatcher.instance.onError = (error, stack) {
      //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      //   return true;
      // };

      /// RevenueCat
      // await initPlatformState();

      runApp(
        ProviderScope(
          observers: [AppObserver()],
          child: EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('vi')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            useOnlyLangCode: true,
            child: const MainApp(),
          ),
        ),
      );
    },
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    _initializeClarity();
  }

  void _initializeClarity() {
    // Initialize Clarity with project ID from environment
    // Set log level based on build mode (verbose in debug, none in release)
    final config = clarity.ClarityConfig(
      projectId: Env.clarityProjectId,
      logLevel: clarity
          .LogLevel
          .None, // Suppress console logs, Clarity still captures data
    );

    // Use WidgetsBinding to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        clarity.Clarity.initialize(context, config);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider);

    // Initialize the provider invalidator and link it to SessionManager
    // This ensures that whenever SessionManager triggers a logout (e.g. on 401),
    // all user-specific Riverpod providers are invalidated.
    final invalidator = ref.read(providerInvalidatorProvider);
    SessionManager.instance.onLogout = invalidator.invalidateUserProviders;

    return MaterialApp.router(
      theme: context.lightTheme,
      darkTheme: context.darkTheme,
      themeMode: themeMode.value,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return OfflineContainer(child: child);
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_mvvm_riverpod/screens/bottomnav/bottomnav.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(

//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home:  BottomNavScreen(),
//     );
//   }
// }
