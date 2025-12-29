import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui';
import '../providers/fare_provider.dart';
import '../services/places_service.dart';
import '../models/place_prediction.dart';
import '../widgets/location_autocomplete_modern.dart';
import 'results_screen_modern.dart';

class HomeScreenModern extends StatefulWidget {
  const HomeScreenModern({super.key});

  @override
  State<HomeScreenModern> createState() => _HomeScreenModernState();
}

class _HomeScreenModernState extends State<HomeScreenModern>
    with SingleTickerProviderStateMixin {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PlacePrediction? _selectedPickupPlace;
  PlacePrediction? _selectedDestinationPlace;
  bool _isCalculatingDistance = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

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

      Map<String, dynamic>? pickupData;
      Map<String, dynamic>? destinationData;

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

      if (pickupData == null || destinationData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to get location coordinates. Please try again.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        setState(() {
          _isCalculatingDistance = false;
        });
        return;
      }

      if (!mounted) return;

      await Provider.of<FareProvider>(context, listen: false).getFareEstimates(
        pickup: pickupData,
        destination: destinationData,
        distance: distance,
        duration: duration,
      );

      if (mounted) {
        // Go directly to results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreenModern(
              pickup: _pickupController.text,
              destination: _destinationController.text,
              pickupData: pickupData!,
              destinationData: destinationData!,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B47ED), // Deep purple
              Color(0xFF7B68EE), // Medium purple
              Color(0xFF9D8FFF), // Light purple
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background circles
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Header
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.directions_car_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Fare Finder',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Compare & Book Your Perfect Ride',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Main Card with glassmorphism
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        // Pickup Location
                                        _buildModernLocationField(
                                          controller: _pickupController,
                                          label: 'Pickup Location',
                                          hint: 'Where are you?',
                                          icon: Icons.trip_origin_rounded,
                                          iconColor: const Color(0xFF10B981),
                                          onPlaceSelected: (place) {
                                            setState(() => _selectedPickupPlace = place);
                                          },
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        // Swap Button
                                        Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.swap_vert_rounded),
                                              color: Colors.white,
                                              iconSize: 28,
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
                                        _buildModernLocationField(
                                          controller: _destinationController,
                                          label: 'Destination',
                                          hint: 'Where to?',
                                          icon: Icons.location_on_rounded,
                                          iconColor: const Color(0xFFEF4444),
                                          onPlaceSelected: (place) {
                                            setState(() => _selectedDestinationPlace = place);
                                          },
                                        ),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Search Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 60,
                                          child: ElevatedButton(
                                            onPressed: _isCalculatingDistance ? null : _searchFares,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF5B47ED),
                                              disabledBackgroundColor: Colors.white.withOpacity(0.3),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                              shadowColor: Colors.black.withOpacity(0.3),
                                            ),
                                            child: _isCalculatingDistance
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Color(0xFF5B47ED),
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'Find Best Rides',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(Icons.arrow_forward_rounded, size: 22),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Feature Pills
                        SlideTransition(
                          position: _slideAnimation,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildFeaturePill('💰 Best Prices'),
                              _buildFeaturePill('⚡ Instant Compare'),
                              _buildFeaturePill('🎯 Smart Choice'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required Function(PlacePrediction) onPlaceSelected,
  }) {
    return LocationAutocompleteModern(
      controller: controller,
      labelText: label,
      hintText: hint,
      prefixIcon: icon,
      iconColor: iconColor,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      onPlaceSelected: onPlaceSelected,
    );
  }

  Widget _buildFeaturePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
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
