import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fare_estimate.dart';
import '../models/booking.dart';
import '../config/network_config.dart';

class ApiService {
  // Use dynamic URL based on platform
  static String get baseUrl => NetworkConfig.getBackendUrl();

  static Future<List<FareEstimate>> getFareEstimates({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required double distance,

    required double duration,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fare-estimate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickup': pickup,
          'destination': destination,
          'distance': distance,
          'duration': duration,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final estimates = (data['estimates'] as List)
            .map((json) => FareEstimate.fromJson(json))
            .toList();
        return estimates;
      } else {
        throw Exception('Failed to get fare estimates');
      }
    } catch (e) {
      throw Exception('Error: $e');
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
