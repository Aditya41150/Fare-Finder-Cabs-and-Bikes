import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/fare_provider.dart';
import 'screens/home_screen_modern.dart'; 
import 'screens/map_preview_screen.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables with fallback
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env file loaded successfully');
    print('📡 BACKEND_URL: ${dotenv.env['BACKEND_URL'] ?? 'not set'}');
  } catch (e) {
    print('⚠️ Warning: .env file not found. Using default configuration.');
    print('Error: $e');
    
    // Initialize dotenv with default values
    dotenv.testLoad(fileInput: '''
GOOGLE_PLACES_API_KEY=
BACKEND_URL=https://fare-finder-cabs-and-bikes-backend.onrender.com/api
''');
    print('✅ Using default backend URL: ${dotenv.env['BACKEND_URL']}');
  }
  
  runApp(const FareFinder());
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
            seedColor: const Color(0xFF6366F1), // Indigo
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          fontFamily: 'SF Pro Display',
        ),
        home: const HomeScreenModern(),
      ),
    );
  }
}



