import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // ─── Compile-time fallbacks ───────────────────────────────────────────────
  // IMPORTANT: Do NOT add real API keys here — keep them in .env only.
  // The backend has mock-data fallback when no Google key is available.
  static const String _fallbackBackendUrl = 'http://localhost:3000/api';

  // Google Places API Configuration — loaded from .env only (never hardcoded)
  static String get googlePlacesApiKey {
    final fromEnv = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    // Optional fallback for Flutter Web / CI builds:
    // flutter run -d chrome --dart-define=GOOGLE_PLACES_API_KEY=...
    const fromDefine = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    return fromDefine.trim();
  }

  // Set this to false when you have a valid Google Places API key
  static const bool useMockPlacesData = false;

  // API Base URLs
  static const String googlePlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Backend URL - reads from .env first, falls back to localhost for local dev
  static String get backendBaseUrl {
    final fromEnv = dotenv.env['BACKEND_URL'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    const fromDefine = String.fromEnvironment('BACKEND_URL');
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return _fallbackBackendUrl;
  }
  
  // Location restrictions (ISO 3166-1 Alpha-2 country code)
  static const String countryRestriction = 'in'; // India
  
  // Autocomplete configuration
  static const int autocompleteDebounceMs = 300;
  static const int maxAutocompleteSuggestions = 5;
  
  // Distance calculation
  static const double averageCitySpeedKmh = 30.0;
  static const double earthRadiusKm = 6371.0;
  
  // Default values for testing
  static const double defaultDistanceKm = 15.5;
  static const double defaultDurationSeconds = 1800; // 30 minutes
  
  // App Information
  static const String appName = 'FareFinder';
  static const String appVersion = '1.0.0';
  
  // Instructions for enabling Google Places API
  static const String placesApiInstructions = '''
1. Go to Google Cloud Console (console.cloud.google.com)
2. Enable Places API and Places API (New)
3. Create API credentials and add GOOGLE_PLACES_API_KEY to .env
''';
}
