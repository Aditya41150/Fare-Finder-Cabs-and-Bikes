import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/fare_provider.dart';
import '../services/places_service.dart';
import '../models/place_prediction.dart';
import '../widgets/location_autocomplete.dart';
import 'results_screen.dart';
import 'package:find_fare/screens/map_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PlacePrediction? _selectedPickupPlace;
  PlacePrediction? _selectedDestinationPlace;
  bool _isCalculatingDistance = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _searchFares() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCalculatingDistance = true;
      });

      double distance = 15.5;
      double duration = 1800;

      // FIXED: Removed () to access static method correctly
      if (_selectedPickupPlace != null && _selectedDestinationPlace != null) {
        try {
          final pickupCoords = await PlacesService.getPlaceCoordinates(
            _selectedPickupPlace!.placeId,
          );
          final destCoords = await PlacesService.getPlaceCoordinates(
            _selectedDestinationPlace!.placeId,
          );

          if (pickupCoords != null && destCoords != null) {
            distance = _calculateDistance(
              pickupCoords['lat']!,
              pickupCoords['lng']!,
              destCoords['lat']!,
              destCoords['lng']!,
            );
            duration = (distance / 30) * 3600;
          }
        } catch (e) {
          debugPrint('Error calculating distance: $e');
        }
      }

      setState(() {
        _isCalculatingDistance = false;
      });

      // Prepare final data maps for coordinates
      Map<String, dynamic>? pickupData;
      Map<String, dynamic>? destinationData;

      // Fetch precise coordinates for search and map
      if (_selectedPickupPlace != null) {
        try {
          final coords = await PlacesService.getPlaceCoordinates(
            _selectedPickupPlace!.placeId,
          );
          if (coords != null) {
            pickupData = {
              'address': _pickupController.text,
              'lat': coords['lat'],
              'lng': coords['lng'],
            };
          }
        } catch (e) {
          debugPrint('Error fetching pickup coordinates: $e');
        }
      }

      if (_selectedDestinationPlace != null) {
        try {
          final coords = await PlacesService.getPlaceCoordinates(
            _selectedDestinationPlace!.placeId,
          );
          if (coords != null) {
            destinationData = {
              'address': _destinationController.text,
              'lat': coords['lat'],
              'lng': coords['lng'],
            };
          }
        } catch (e) {
          debugPrint('Error fetching destination coordinates: $e');
        }
      }

      // Validate that we have both coordinates
      if (pickupData == null || destinationData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location coordinates. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCalculatingDistance = false;
        });
        return;
      }

      if (!mounted) return;

      // Fetch the cab estimates from your Node.js backend
      await Provider.of<FareProvider>(context, listen: false).getFareEstimates(
        pickup: pickupData,
        destination: destinationData,
        distance: distance,
        duration: duration,
      );

      if (mounted) {
        // First show the route on the map
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MapScreen(pickup: pickupData, destination: destinationData),
          ),
        );

        // Then show results screen after map is dismissed
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                pickup: _pickupController.text,
                destination: _destinationController.text,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Fare'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[600]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Compare Cab Fares',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Find the best deals from multiple cab services',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          LocationAutocomplete(
                            controller: _pickupController,
                            labelText: 'Pickup Location',
                            hintText: 'Search for pickup location',
                            prefixIcon: Icons.my_location,
                            iconColor: Colors.green,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              return null;
                            },
                            onPlaceSelected: (place) {
                              setState(() => _selectedPickupPlace = place);
                            },
                          ),
                          const SizedBox(height: 20),
                          LocationAutocomplete(
                            controller: _destinationController,
                            labelText: 'Destination',
                            hintText: 'Search for destination',
                            prefixIcon: Icons.place,
                            iconColor: Colors.red,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              return null;
                            },
                            onPlaceSelected: (place) {
                              setState(() => _selectedDestinationPlace = place);
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isCalculatingDistance
                                  ? null
                                  : _searchFares,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: _isCalculatingDistance
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Search Fares',
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureCard(Icons.compare, 'Compare\nPrices'),
                      _buildFeatureCard(
                        Icons.access_time,
                        'Real-time\nUpdates',
                      ),
                      _buildFeatureCard(Icons.attach_money, 'Save\nMoney'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.blue[600]),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
