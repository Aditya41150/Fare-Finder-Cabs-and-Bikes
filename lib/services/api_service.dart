import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fare_estimate.dart';
import '../models/booking.dart';
import '../config/app_config.dart';

class ApiService {
  // Use backend URL from .env file (supports both local and production)
  static String get baseUrl => AppConfig.backendBaseUrl;

  static Future<List<FareEstimate>> getFareEstimates({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required double distance,
    required double duration,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/fare-estimate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pickup': pickup,
              'destination': destination,
              'distance': distance,
              'duration': duration,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid fare response');
        }
        final rawEstimates = decoded['estimates'];
        if (rawEstimates is! List) {
          throw Exception('No fare estimates returned');
        }
        final estimates = rawEstimates
            .whereType<Map>()
            .map((json) =>
                FareEstimate.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        estimates.sort((a, b) => a.estimatedFare.compareTo(b.estimatedFare));
        return estimates;
      } else {
        throw Exception('Fare service returned ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Fare service took too long. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to get fare estimates');
    }
  }

  /// Fire-and-forget: wakes the Render free-tier backend so it is warm
  /// by the time the user searches for fares. Never throws.
  static Future<void> pingBackend() async {
    try {
      await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 30));
      debugPrint('✅ Backend warm-up ping succeeded');
    } catch (e) {
      debugPrint('⚠️ Backend warm-up ping failed (will retry on search): $e');
    }
  }

  static Future<bool> createBooking({
    required String userId,
    required String serviceId,
    required String pickup,
    required String destination,
    required int fare,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'serviceId': serviceId,
          'pickup': pickup,
          'destination': destination,
          'fare': fare,
          'bookingTime': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = (data['bookings'] as List)
            .map((json) => Booking.fromJson(json))
            .toList();
        return bookings;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
