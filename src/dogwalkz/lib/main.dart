import 'package:dogwalkz/pages/dogs_page.dart';
import 'package:dogwalkz/pages/schedule_walk_page.dart';
import 'package:dogwalkz/pages/walks_page.dart';

import 'package:dogwalkz/pages/wallet_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dogwalkz/constants/supabase.dart';
import 'package:dogwalkz/services/language_service.dart';
import 'splash_screen.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';

/// The main entry point of the application.
/// It initializes the Supabase client, loads the environment variables,
/// and sets up the app's routing.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: SupabaseCredentials.url,
    anonKey: SupabaseCredentials.anonKey,
  );

  // Load saved language
  final savedLanguage = await LanguageService.getLanguage();
  final locale =
      savedLanguage != null ? Locale(savedLanguage) : const Locale('en');

  runApp(MyApp(locale: locale));
}

class MyApp extends StatefulWidget {
  final Locale locale;

  const MyApp({super.key, required this.locale});

  @override
  State<MyApp> createState() => _MyAppState();

  /// A method to access the state of MyApp from anywhere in the widget tree.
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  /// Initializes the state of the app with the provided locale.
  @override
  void initState() {
    super.initState();
    // Initialize the app with the saved or default locale
    _locale = widget.locale;
  }

  /// Sets the locale of the app and saves the selected language to shared preferences.
  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    // Save the selected language
    await LanguageService.saveLanguage(locale.languageCode);
  }

  ///Builds the app's UI with the specified locale and routes.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
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
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
        '/dogs': (context) => const DogsPage(),
        '/wallet': (context) => const WalletPage(),
        '/profile': (context) => const ProfilePage(),
        '/walks': (context) => const WalksPage(),
        '/schedule-walk': (context) => const ScheduleWalkPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
