import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/place_prediction.dart';
import '../config/app_config.dart';

class PlacesService {
  // Use backend URL from .env file (supports both local and production)
  static String get baseUrl => AppConfig.backendBaseUrl;

  static Uri _buildUri(
    String endpoint,
    Map<String, String> queryParameters,
  ) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl/$endpoint').replace(
      queryParameters: queryParameters,
    );
  }

  static Future<List<PlacePrediction>> _getAutocompleteFromGoogle(
    String input,
  ) async {
    final apiKey = AppConfig.googlePlacesApiKey;
    if (apiKey.isEmpty) return [];

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
    ).replace(
      queryParameters: {
        'input': input,
        'key': apiKey,
        'components': 'country:${AppConfig.countryRestriction}',
        'types': 'geocode',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    final predictions = (data['predictions'] as List<dynamic>?) ?? [];

    if (status != 'OK' && status != 'ZERO_RESULTS') return [];
    return predictions
        .map((item) => PlacePrediction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ─── App-side mock fallback (works on web without backend/Google) ─────────
  // This is intentionally tiny: it keeps the UX functional when the backend is
  // unavailable (common on Flutter Web demos) and avoids CORS-blocked calls to
  // Google Places Web Service.
  static const List<Map<String, String>> _mockLocations = [
    {'description': 'Bangalore, Karnataka, India', 'place_id': 'mock_blr_1'},
    {
      'description': 'MG Road, Bangalore, Karnataka, India',
      'place_id': 'mock_blr_mg'
    },
    {
      'description': 'Koramangala, Bangalore, Karnataka, India',
      'place_id': 'mock_blr_kmg'
    },
    {
      'description': 'Indiranagar, Bangalore, Karnataka, India',
      'place_id': 'mock_blr_inr'
    },
    {
      'description': 'Whitefield, Bangalore, Karnataka, India',
      'place_id': 'mock_blr_wtf'
    },
    {
      'description': 'Electronic City, Bangalore, Karnataka, India',
      'place_id': 'mock_blr_ec'
    },
    {'description': 'Mumbai, Maharashtra, India', 'place_id': 'mock_mum_1'},
    {
      'description': 'Andheri, Mumbai, Maharashtra, India',
      'place_id': 'mock_mum_and'
    },
    {
      'description': 'Bandra, Mumbai, Maharashtra, India',
      'place_id': 'mock_mum_ban'
    },
    {'description': 'Delhi, India', 'place_id': 'mock_del_1'},
    {'description': 'Connaught Place, Delhi, India', 'place_id': 'mock_del_cp'},
    {'description': 'Pune, Maharashtra, India', 'place_id': 'mock_pun_1'},
    {'description': 'Hyderabad, Telangana, India', 'place_id': 'mock_hyd_1'},
    {'description': 'Chennai, Tamil Nadu, India', 'place_id': 'mock_che_1'},
  ];

  static const Map<String, Map<String, double>> _mockCoordinates = {
    'mock_blr_1': {'lat': 12.9716, 'lng': 77.5946},
    'mock_blr_mg': {'lat': 12.9759, 'lng': 77.6061},
    'mock_blr_kmg': {'lat': 12.9352, 'lng': 77.6245},
    'mock_blr_inr': {'lat': 12.9784, 'lng': 77.6408},
    'mock_blr_wtf': {'lat': 12.9698, 'lng': 77.7500},
    'mock_blr_ec': {'lat': 12.8456, 'lng': 77.6603},
    'mock_mum_1': {'lat': 19.0760, 'lng': 72.8777},
    'mock_mum_and': {'lat': 19.1136, 'lng': 72.8697},
    'mock_mum_ban': {'lat': 19.0596, 'lng': 72.8295},
    'mock_del_1': {'lat': 28.7041, 'lng': 77.1025},
    'mock_del_cp': {'lat': 28.6315, 'lng': 77.2167},
    'mock_pun_1': {'lat': 18.5204, 'lng': 73.8567},
    'mock_hyd_1': {'lat': 17.3850, 'lng': 78.4867},
    'mock_che_1': {'lat': 13.0827, 'lng': 80.2707},
  };

  static List<PlacePrediction> _getMockPredictions(String input) {
    final query = input.trim().toLowerCase();
    if (query.isEmpty) return [];
    return _mockLocations
        .where(
          (l) => (l['description'] ?? '').toLowerCase().contains(query),
        )
        .take(AppConfig.maxAutocompleteSuggestions)
        .map((l) => PlacePrediction.fromJson(l))
        .toList();
  }

  static Map<String, double>? _getMockCoordinates(String placeId) {
    final coords = _mockCoordinates[placeId];
    if (coords == null) return null;
    return {'lat': coords['lat']!, 'lng': coords['lng']!};
  }

  static Future<Map<String, double>?> _getPlaceCoordinatesFromGoogle(
    String placeId,
  ) async {
    final apiKey = AppConfig.googlePlacesApiKey;
    if (apiKey.isEmpty) return null;

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json',
    ).replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;

    final location = data['result']?['geometry']?['location'];
    if (location == null) return null;

    return {
      'lat': (location['lat'] as num).toDouble(),
      'lng': (location['lng'] as num).toDouble(),
    };
  }

  static PlacePrediction _pickBestPrediction(
    String query,
    List<PlacePrediction> predictions,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    for (final prediction in predictions) {
      if (prediction.description.trim().toLowerCase() == normalizedQuery) {
        return prediction;
      }
    }

    for (final prediction in predictions) {
      if (prediction.description.toLowerCase().contains(normalizedQuery)) {
        return prediction;
      }
    }

    return predictions.first;
  }

  static Future<Map<String, double>?> _geocodeWithNominatim(
      String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final queryTokens = normalizedQuery
        .split(RegExp(r'\s+|,'))
        .map((e) => e.trim())
        .where((e) => e.length >= 3)
        .toList();

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '0',
      'countrycodes': AppConfig.countryRestriction,
    });

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;

    Map<String, dynamic>? best;
    var bestScore = -1;

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final displayName = (item['display_name'] ?? '').toString().toLowerCase();
      var score = 0;
      for (final token in queryTokens) {
        if (displayName.contains(token)) score += 1;
      }
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    best ??= decoded.first is Map<String, dynamic>
        ? decoded.first as Map<String, dynamic>
        : null;
    if (best == null) return null;

    final latRaw = best['lat'];
    final lonRaw = best['lon'];
    if (latRaw == null || lonRaw == null) return null;

    final lat = double.tryParse(latRaw.toString());
    final lng = double.tryParse(lonRaw.toString());
    if (lat == null || lng == null) return null;

    return {
      'lat': lat,
      'lng': lng,
    };
  }

  static Future<Map<String, double>?> getCoordinatesFromText(
      String input) async {
    final query = input.trim();
    if (query.isEmpty) return null;

    try {
      final predictions = await getAutocompletePredictions(query);
      if (predictions.isNotEmpty) {
        final bestMatch = _pickBestPrediction(query, predictions);
        final coords = await getPlaceCoordinates(bestMatch.placeId);
        if (coords != null) {
          return coords;
        }
      }
    } catch (_) {}

    try {
      return await _geocodeWithNominatim(query);
    } catch (_) {
      return null;
    }
  }

  // ─── Free road-distance via OSRM (open source routing, no API key) ────────
  /// Returns {'distance': km, 'duration': seconds} or null on failure.
  static Future<Map<String, double>?> getRoadDistanceOSRM(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$fromLng,$fromLat;$toLng,$toLat'
        '?overview=false&steps=false',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).toDouble();

      return {
        'distance': distanceMeters / 1000, // metres → km
        'duration': durationSeconds,        // seconds
      };
    } catch (_) {
      return null;
    }
  }

  // Add these inside your PlacesService class
  static Future<Map<String, dynamic>?> getRoadDistance(
    String origin,
    String destination,
  ) async {
    final response = await http.get(
      _buildUri('distance', {
        'origin': origin,
        'destination': destination,
      }),
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : null;
  }

  static Future<String?> getRoutePoints(
    String origin,
    String destination,
  ) async {
    final response = await http.get(
      _buildUri('directions', {
        'origin': origin,
        'destination': destination,
      }),
    );
    return response.statusCode == 200
        ? jsonDecode(response.body)['points']
        : null;
  }

  // Method 1: Get search suggestions
  static Future<List<PlacePrediction>> getAutocompletePredictions(
    String input,
  ) async {
    if (input.isEmpty) return [];

    // On Android/iOS: call Google Places API directly first.
    // The hosted Render backend may be in mock-data mode (when its
    // GOOGLE_MAPS_API_KEY env var is not configured on the server), so
    // calling Google directly gives real suggestions immediately.
    if (!kIsWeb) {
      final apiKey = AppConfig.googlePlacesApiKey;
      if (apiKey.isNotEmpty) {
        try {
          print('🔍 Calling Google Places API directly for: $input');
          final google = await _getAutocompleteFromGoogle(input);
          if (google.isNotEmpty) {
            print('✅ Google Places returned ${google.length} predictions');
            return google;
          }
          print('ℹ️ Google Places returned 0 results, falling back to backend...');
        } catch (e) {
          print('⚠️ Direct Google Places call failed: $e — falling back to backend');
        }
      }
    }

    // Web (or when the Google key is absent): route through the backend.
    try {
      print('🔍 Fetching autocomplete via backend for: $input');
      print('📡 Backend URL from AppConfig: $baseUrl');

      final uri = _buildUri('places-autocomplete', {'input': input});
      print('🌐 Full URL: $uri');

      final response = await http.get(uri);

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📦 Response body: ${response.body}');
        final decoded = jsonDecode(response.body);
        final List<dynamic> predictions = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic>
                ? (decoded['predictions'] ?? [])
                : []);

        // Detect whether the backend is serving mock data.
        final String source = decoded is Map<String, dynamic>
            ? (decoded['source'] as String? ?? '')
            : '';
        final bool backendIsMock =
            source == 'mock' || source == 'mock-fallback';

        print('✅ Got ${predictions.length} predictions (source: $source)');

        if (predictions.isNotEmpty && !backendIsMock) {
          // Backend returned real Google predictions — use them.
          return predictions
              .map((json) => PlacePrediction.fromJson(json))
              .toList();
        }

        // Backend in mock mode or no results — use app-side mock list.
        print(backendIsMock
            ? 'ℹ️ Backend in mock mode. Using app-side mock fallback...'
            : 'ℹ️ Backend returned no predictions. Using app-side mock fallback...');
        return _getMockPredictions(input);
      } else {
        print('❌ Error: Status code ${response.statusCode}');
        print('Response: ${response.body}');
        return _getMockPredictions(input);
      }
    } catch (e) {
      print('❌ Autocomplete Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      return _getMockPredictions(input);
    }
  }

  // Method 2: Get Lat/Lng for the selected place
  static Future<Map<String, double>?> getPlaceCoordinates(
    String placeId,
  ) async {
    if (placeId.trim().isEmpty) return null;
    if (placeId.startsWith('mock_')) return _getMockCoordinates(placeId);

    // On Android/iOS: try Google Places API directly first (same reason as above).
    if (!kIsWeb) {
      try {
        final coords = await _getPlaceCoordinatesFromGoogle(placeId);
        if (coords != null) return coords;
      } catch (_) {}
    }

    try {
      final response = await http.get(
        _buildUri('place-details', {'placeId': placeId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['lat'] == null || data['lng'] == null) {
          if (kIsWeb) return null;
          return await _getPlaceCoordinatesFromGoogle(placeId);
        }
        // Returns the coordinates from your Node.js response
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
        };
      }

      if (kIsWeb) return null;
      return await _getPlaceCoordinatesFromGoogle(placeId);
    } catch (e) {
      print('Coordinate Error: $e');
      if (kIsWeb) return null;
      return await _getPlaceCoordinatesFromGoogle(placeId);
    }
  }
}
