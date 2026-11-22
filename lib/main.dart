import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/fare_provider.dart';
import 'screens/home_screen_modern.dart';
import 'services/api_service.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized6
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with fallback.
  // NOTE: On Flutter Web, .env loading may fail — AppConfig has
  //       compile-time fallbacks so the app still works correctly.
  try {
    await dotenv.load(fileName: ".env");
    print(
        '✅ .env file loaded: BACKEND_URL=${dotenv.env['BACKEND_URL'] ?? 'not set'}');
  } catch (e) {
    print(
        '⚠️ .env not loaded (normal on Flutter Web). Using compile-time fallbacks.');
    // Load empty map so dotenv.env lookups don't throw — AppConfig fallbacks take over
    dotenv.testLoad(fileInput: '');
  }

  // Fire-and-forget warm-up ping so the Render backend is awake
  // by the time the user taps "Find Best Rides".
  ApiService.pingBackend();

  runApp(FareFinder());
}

class FareFinder extends StatelessWidget {
  const FareFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FareProvider()),
      ],
      child: MaterialApp(
        title: 'Fare Finder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF6C744),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F7F5),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: const Color(0xFFE6E6E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: const Color(0xFFE6E6E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF1F2933), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFFF7F7F5),
            foregroundColor: Color(0xFF1F2933),
          ),
          fontFamily: 'SF Pro Display',
        ),
        home: const HomeScreenModern(),
      ),
    );
  }
}
