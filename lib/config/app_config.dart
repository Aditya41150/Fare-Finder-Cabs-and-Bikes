import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Google Places API Configuration
  static String get googlePlacesApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  
  // Set this to false when you have a valid Google Places API key
  static const bool useMockPlacesData = false;
  
  // API Base URLs
  static const String googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String backendBaseUrl = 'http://192.168.1.39:3000/api';
  
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
To enable real Google Places API:
1. Go to Google Cloud Console
2. Create a new project or select existing one
3. Enable Places API and Geocoding API
4. Create credentials (API Key)
5. Replace 'YOUR_GOOGLE_PLACES_API_KEY' with your actual API key
6. Set useMockPlacesData to false
7. Restart the app
''';
}
