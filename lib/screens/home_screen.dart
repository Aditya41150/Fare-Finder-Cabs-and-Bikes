import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/fare_provider.dart';
import '../services/places_service.dart';
import '../models/place_prediction.dart';
import '../widgets/location_autocomplete.dart';
import 'results_screen.dart';
import 'map_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PlacePrediction? _selectedPickupPlace;
  PlacePrediction? _selectedDestinationPlace;
  bool _isCalculatingDistance = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _searchFares() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCalculatingDistance = true;
      });

      double distance = 15.5;
      double duration = 1800;

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
            SnackBar(
              content: const Text('Unable to get location coordinates. Please try again.'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                MapScreen(pickup: pickupData!, destination: destinationData!),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFA855F7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // App Title
                        const Text(
                          '🚗 Fare Finder',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Compare cab fares instantly',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        
                        // Main Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                // Pickup Location
                                LocationAutocomplete(
                                  controller: _pickupController,
                                  labelText: 'Pickup Location',
                                  hintText: 'Where are you?',
                                  prefixIcon: Icons.my_location_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter pickup location';
                                    }
                                    return null;
                                  },
                                  onPlaceSelected: (place) {
                                    setState(() => _selectedPickupPlace = place);
                                  },
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Swap Button
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.swap_vert_rounded),
                                      color: const Color(0xFF6366F1),
                                      onPressed: () {
                                        final temp = _pickupController.text;
                                        _pickupController.text = _destinationController.text;
                                        _destinationController.text = temp;
                                        
                                        final tempPlace = _selectedPickupPlace;
                                        _selectedPickupPlace = _selectedDestinationPlace;
                                        _selectedDestinationPlace = tempPlace;
                                      },
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Destination Location
                                LocationAutocomplete(
                                  controller: _destinationController,
                                  labelText: 'Destination',
                                  hintText: 'Where to?',
                                  prefixIcon: Icons.location_on_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter destination';
                                    }
                                    return null;
                                  },
                                  onPlaceSelected: (place) {
                                    setState(() => _selectedDestinationPlace = place);
                                  },
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Search Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isCalculatingDistance ? null : _searchFares,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey.shade300,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isCalculatingDistance
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Compare Fares',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Feature Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.compare_arrows_rounded,
                                'Compare\nPrices',
                                const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.bolt_rounded,
                                'Instant\nResults',
                                const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.savings_rounded,
                                'Save\nMoney',
                                const Color(0xFFA855F7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
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
