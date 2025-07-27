import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/fare_provider.dart';
import '../services/places_service.dart';
import '../widgets/location_autocomplete.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

      double distance = 15.5; // Default fallback distance
      double duration = 1800; // Default fallback duration (30 minutes)

      // Calculate actual distance if both places are selected
      if (_selectedPickupPlace != null && _selectedDestinationPlace != null) {
        try {
          final pickupCoords = await PlacesService.getPlaceCoordinates(_selectedPickupPlace!.placeId);
          final destCoords = await PlacesService.getPlaceCoordinates(_selectedDestinationPlace!.placeId);
          
          if (pickupCoords != null && destCoords != null) {
            distance = _calculateDistance(
              pickupCoords['lat']!,
              pickupCoords['lng']!,
              destCoords['lat']!,
              destCoords['lng']!,
            );
            // Estimate duration based on distance (assuming average speed of 30 km/h in city traffic)
            duration = (distance / 30) * 3600; // Convert hours to seconds
          }
        } catch (e) {
          print('Error calculating distance: $e');
          // Use fallback values
        }
      }

      setState(() {
        _isCalculatingDistance = false;
      });

      // Prepare pickup and destination objects
      Map<String, dynamic> pickupData = {
        'address': _pickupController.text,
        'lat': 12.9716, // Default to Bangalore coordinates
        'lng': 77.5946,
      };
      
      Map<String, dynamic> destinationData = {
        'address': _destinationController.text,
        'lat': 12.2958, // Default to Mysuru coordinates  
        'lng': 76.6394,
      };
      
      // Use actual coordinates if available
      if (_selectedPickupPlace != null) {
        try {
          final pickupCoords = await PlacesService.getPlaceCoordinates(_selectedPickupPlace!.placeId);
          if (pickupCoords != null) {
            pickupData['lat'] = pickupCoords['lat'];
            pickupData['lng'] = pickupCoords['lng'];
          }
        } catch (e) {
          print('Error getting pickup coordinates: $e');
        }
      }
      
      if (_selectedDestinationPlace != null) {
        try {
          final destCoords = await PlacesService.getPlaceCoordinates(_selectedDestinationPlace!.placeId);
          if (destCoords != null) {
            destinationData['lat'] = destCoords['lat'];
            destinationData['lng'] = destCoords['lng'];
          }
        } catch (e) {
          print('Error getting destination coordinates: $e');
        }
      }

      await Provider.of<FareProvider>(context, listen: false).getFareEstimates(
        pickup: pickupData,
        destination: destinationData,
        distance: distance,
        duration: duration,
      );

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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
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
                              if (value == null || value.isEmpty) {
                                return 'Please enter pickup location';
                              }
                              return null;
                            },
                            onPlaceSelected: (place) {
                              setState(() {
                                _selectedPickupPlace = place;
                              });
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
                              if (value == null || value.isEmpty) {
                                return 'Please enter destination';
                              }
                              return null;
                            },
                            onPlaceSelected: (place) {
                              setState(() {
                                _selectedDestinationPlace = place;
                              });
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isCalculatingDistance ? null : _searchFares,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                              child: _isCalculatingDistance
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Calculating...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Search Fares',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                      _buildFeatureCard(Icons.access_time, 'Real-time\nUpdates'),
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
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.blue[600]),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
        cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) *
        sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
