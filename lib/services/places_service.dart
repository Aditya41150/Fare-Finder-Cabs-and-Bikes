import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_prediction.dart';
import '../config/app_config.dart';

class PlacesService {
  // Use backend URL from .env file (supports both local and production)
  static String get baseUrl => AppConfig.backendBaseUrl;
  // Add these inside your PlacesService class
  static Future<Map<String, dynamic>?> getRoadDistance(
    String origin,
    String destination,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/distance?origin=$origin&destination=$destination'),
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : null;
  }

  static Future<String?> getRoutePoints(
    String origin,
    String destination,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/directions?origin=$origin&destination=$destination'),
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

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/places-autocomplete?input=$input'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Handle the wrapped response format from backend
        final List<dynamic> predictions = data['predictions'] ?? [];
        return predictions.map((json) => PlacePrediction.fromJson(json)).toList();
      }
    } catch (e) {
      print('Autocomplete Error: $e');
    }
    return [];
  }

  // Method 2: Get Lat/Lng for the selected place
  static Future<Map<String, double>?> getPlaceCoordinates(
    String placeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/place-details?placeId=$placeId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Returns the coordinates from your Node.js response
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
        };
      }
    } catch (e) {
      print('Coordinate Error: $e');
    }
    return null;
  }
}
