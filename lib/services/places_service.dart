import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlacesService {
  static const String _apiKey = AppConfig.googlePlacesApiKey;
  static const String _baseUrl = AppConfig.googlePlacesBaseUrl;
  static const bool _useMockData = AppConfig.useMockPlacesData;

  static Future<List<PlacePrediction>> getAutocompletePredictions(String input) async {
    if (input.isEmpty) return [];

    try {
      if (_useMockData) {
        // For demo purposes, return mock predictions
        return _getMockPredictions(input);
      } else {
        // Real Google Places API integration
        final url = Uri.parse(
          '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&types=geocode&components=country:${AppConfig.countryRestriction}',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK') {
            final predictions = (data['predictions'] as List)
                .map((json) => PlacePrediction.fromJson(json))
                .toList();
            return predictions;
          } else {
            print('Google Places API error: ${data['status']}');
            return _getMockPredictions(input); // Fallback to mock data
          }
        } else {
          print('HTTP error: ${response.statusCode}');
          return _getMockPredictions(input); // Fallback to mock data
        }
      }
    } catch (e) {
      print('Error fetching predictions: $e');
      return _getMockPredictions(input); // Fallback to mock data
    }
  }

  // Mock predictions for demo (replace with real API in production)
  static List<PlacePrediction> _getMockPredictions(String input) {
    final mockPlaces = [
      {'main': 'Connaught Place', 'secondary': 'New Delhi, Delhi, India'},
      {'main': 'India Gate', 'secondary': 'New Delhi, Delhi, India'},
      {'main': 'Red Fort', 'secondary': 'Chandni Chowk, New Delhi, Delhi, India'},
      {'main': 'Cyber City', 'secondary': 'Gurgaon, Haryana, India'},
      {'main': 'MG Road', 'secondary': 'Bangalore, Karnataka, India'},
      {'main': 'Bandra', 'secondary': 'Mumbai, Maharashtra, India'},
      {'main': 'Koramangala', 'secondary': 'Bangalore, Karnataka, India'},
      {'main': 'Andheri', 'secondary': 'Mumbai, Maharashtra, India'},
      {'main': 'Sector 18', 'secondary': 'Noida, Uttar Pradesh, India'},
      {'main': 'Electronic City', 'secondary': 'Bangalore, Karnataka, India'},
    ];

    return mockPlaces
        .where((place) => 
            place['main']!.toLowerCase().contains(input.toLowerCase()) ||
            place['secondary']!.toLowerCase().contains(input.toLowerCase()))
        .map((place) => PlacePrediction(
              placeId: place['main']!.replaceAll(' ', '_').toLowerCase(),
              description: '${place['main']}, ${place['secondary']}',
              mainText: place['main']!,
              secondaryText: place['secondary']!,
            ))
        .take(AppConfig.maxAutocompleteSuggestions)
        .toList();
  }

  static Future<Map<String, double>?> getPlaceCoordinates(String placeId) async {
    try {
      if (_useMockData) {
        // Mock coordinates for demo
        final mockCoordinates = {
          'connaught_place': {'lat': 28.6315, 'lng': 77.2167},
          'india_gate': {'lat': 28.6129, 'lng': 77.2295},
          'red_fort': {'lat': 28.6562, 'lng': 77.2410},
          'cyber_city': {'lat': 28.4956, 'lng': 77.0869},
          'mg_road': {'lat': 12.9716, 'lng': 77.5946},
          'bandra': {'lat': 19.0544, 'lng': 72.8406},
          'koramangala': {'lat': 12.9352, 'lng': 77.6245},
          'andheri': {'lat': 19.1136, 'lng': 72.8697},
          'sector_18': {'lat': 28.5693, 'lng': 77.3250},
          'electronic_city': {'lat': 12.8456, 'lng': 77.6603},
        };

        final coords = mockCoordinates[placeId];
        if (coords != null) {
          return {'lat': coords['lat']!, 'lng': coords['lng']!};
        }
      } else {
        // Real Google Places API integration
        final url = Uri.parse(
          '$_baseUrl/details/json?place_id=$placeId&fields=geometry&key=$_apiKey',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK') {
            final location = data['result']['geometry']['location'];
            return {
              'lat': location['lat'].toDouble(),
              'lng': location['lng'].toDouble(),
            };
          } else {
            print('Google Places Details API error: ${data['status']}');
          }
        } else {
          print('HTTP error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching place coordinates: $e');
    }

    return null;
  }
}
