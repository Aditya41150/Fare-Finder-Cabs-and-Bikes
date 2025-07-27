import 'package:flutter/material.dart';
import '../models/fare_estimate.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class FareProvider with ChangeNotifier {
  List<FareEstimate> _estimates = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String _error = '';

  List<FareEstimate> get estimates => _estimates;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> getFareEstimates({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required double distance,
    required double duration,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _estimates = await ApiService.getFareEstimates(
        pickup: pickup,
        destination: destination,
        distance: distance,
        duration: duration,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> bookCab({
    required String userId,
    required FareEstimate estimate,
    required String pickup,
    required String destination,
  }) async {
    try {
      final success = await ApiService.createBooking(
        userId: userId,
        serviceId: estimate.id,
        pickup: pickup,
        destination: destination,
        fare: estimate.estimatedFare,
      );
      
      if (success) {
        await getUserBookings(userId);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> getUserBookings(String userId) async {
    try {
      _bookings = await ApiService.getUserBookings(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
