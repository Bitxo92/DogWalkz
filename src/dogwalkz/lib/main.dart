import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dogwalkz/pages/dogs_page.dart';
import 'package:dogwalkz/pages/notifications_page.dart';
import 'package:dogwalkz/pages/password_reset_page.dart';
import 'package:dogwalkz/pages/schedule_walk_page.dart';
import 'package:dogwalkz/pages/walks_page.dart';
import 'package:dogwalkz/pages/wallet_page.dart';
import 'package:dogwalkz/services/fcm_service.dart';

import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dogwalkz/constants/supabase.dart';
import 'package:dogwalkz/services/language_service.dart';
import 'splash_screen.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';

/// The main entry point of the application.
/// It initializes the Supabase client, loads the environment variables,
/// FCM service, and sets up the app's routing.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseCredentials.url,
    anonKey: SupabaseCredentials.anonKey,
  );

  // Initialize FCM service
  try {
    await FCMService.initialize();
    print('FCM service initialized successfully');
  } catch (e) {
    print('Error initializing FCM service: $e');
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.signedIn) {
      FCMService.validateAndRefreshToken(force: true);
    }
  });

  // Load saved language
  final savedLanguage = await LanguageService.getLanguage();
  final locale =
      savedLanguage != null ? Locale(savedLanguage) : const Locale('en');

  final appLinks = AppLinks();
  final initialUri = await appLinks.getInitialLink();

  runApp(MyApp(locale: locale, initialUri: initialUri));
}

class MyApp extends StatefulWidget {
  final Locale locale;
  final Uri? initialUri;

  const MyApp({super.key, required this.locale, this.initialUri});

  @override
  State<MyApp> createState() => _MyAppState();

  /// A method to access the state of MyApp from anywhere in the widget tree.
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Locale _locale;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  final NotificationService _notificationService = NotificationService();

  /// Initializes the state of the app with the provided locale.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize the app with the saved or default locale
    _locale = widget.locale;

    // Setup notification listeners
    _setupNotificationListeners();

    // Handle deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialUri != null) {
        _handleDeepLink(widget.initialUri!);
      }
      _setupDeepLinks(); // continue listening for new links
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _notificationService.dispose();
    FCMService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        FCMService.onAppResume();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Setup notification listeners for handling notification taps
  void _setupNotificationListeners() {
    _notificationSubscription = FCMService.notificationStream.listen(
      (notificationData) {
        _handleNotificationTap(notificationData);
      },
      onError: (error) {
        print('Error in notification stream: $error');
      },
    );
  }

  /// Handle notification tap and navigate to appropriate screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String?;
    final action = data['action'] as String?;

    switch (type) {
      case 'walk_scheduled':
      case 'walk_completed':
      case 'walk_cancelled':
      case 'walk_reminder':
        final walkId = data['walk_id'] as String?;
        if (walkId != null) {
          Navigator.of(context).pushNamed('/notifications');
        }
        break;

      case 'new_message':
        final walkId = data['walk_id'] as String?;
        if (walkId != null) {
          // Navigate to chat/message screen
          Navigator.of(context).pushNamed('/notifications');
        }
        break;

      case 'payment_received':
        Navigator.of(context).pushNamed('/wallet');
        break;

      default:
        // Navigate to home for unknown notification types
        Navigator.of(context).pushNamed('/home');
        break;
    }
  }

  /// Sets the locale of the app and saves the selected language to shared preferences.
  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    // Save the selected language
    await LanguageService.saveLanguage(locale.languageCode);
  }

  //Method to handle deep links
  void _setupDeepLinks() async {
    final appLinks = AppLinks();

    // Handle initial link if app was launched from a deep link
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Listen to incoming links while the app is running
    appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'reset-password') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PasswordResetPage()),
      );
    }
  }

  // Global navigator key for accessing navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ///Builds the app's UI with the specified locale and routes.
  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder:
          (context) => MaterialApp(
            navigatorKey: navigatorKey,
            title: 'DogWalkz',
            locale: _locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              primarySwatch: Colors.brown,
              primaryColor: Colors.brown,
              scaffoldBackgroundColor: const Color(0xFFF5E9D9),
              focusColor: Colors.brown,
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: Colors.brown,
                selectionColor: Colors.brown.withOpacity(0.5),
                selectionHandleColor: Colors.brown,
              ),
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.brown, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.brown.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade700,
                    width: 2.0,
                  ),
                ),
                floatingLabelStyle: TextStyle(color: Colors.brown),
                labelStyle: TextStyle(color: Colors.brown.withOpacity(0.9)),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.brown),
              ),
              iconTheme: IconThemeData(color: Colors.brown),
              primaryIconTheme: IconThemeData(color: Colors.brown),
              textTheme: GoogleFonts.comicNeueTextTheme(),
              primaryTextTheme: GoogleFonts.comicNeueTextTheme(),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(initialUri: widget.initialUri),
              '/auth': (context) => const AuthPage(),
              '/home': (context) => const HomePage(),
              '/dogs': (context) => const DogsPage(),
              '/wallet': (context) => const WalletPage(),
              '/profile': (context) => const ProfilePage(),
              '/walks': (context) => const WalksPage(),
              '/schedule-walk': (context) => const ScheduleWalkPage(),
              '/notifications': (context) => const NotificationsPage(),
            },
            debugShowCheckedModeBanner: false,
          ),
      blurValue: 0,
    );
  }
}
