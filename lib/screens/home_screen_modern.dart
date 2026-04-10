import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  Map<String, double>? _pickupCoordinates;
  Map<String, double>? _destinationCoordinates;
  String? _resolvedPickupText;
  String? _resolvedDestinationText;
  bool _isCalculatingDistance = false;
  bool _isFetchingCurrentLocation = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // If the user edits text after selecting a suggestion, clear the cached
    // selection/coordinates so we don't calculate with stale placeIds.
    _pickupController.addListener(() {
      final text = _pickupController.text.trim();
      if (_resolvedPickupText != null && text != _resolvedPickupText) {
        _resolvedPickupText = null;
        _selectedPickupPlace = null;
        _pickupCoordinates = null;
      }
    });
    _destinationController.addListener(() {
      final text = _destinationController.text.trim();
      if (_resolvedDestinationText != null &&
          text != _resolvedDestinationText) {
        _resolvedDestinationText = null;
        _selectedDestinationPlace = null;
        _destinationCoordinates = null;
      }
    });

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

  Future<void> _useCurrentLocationForPickup() async {
    if (_isFetchingCurrentLocation) return;

    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location services are disabled. Please enable GPS.'),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission denied. Please allow permission.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String addressText =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final locality = place.locality?.trim() ?? '';
          final subLocality = place.subLocality?.trim() ?? '';
          final administrativeArea = place.administrativeArea?.trim() ?? '';

          final parts = [subLocality, locality, administrativeArea]
              .where((part) => part.isNotEmpty)
              .toList();

          if (parts.isNotEmpty) {
            addressText = parts.join(', ');
          }
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _pickupController.text = addressText;
        _selectedPickupPlace = null;
        _pickupCoordinates = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
        _resolvedPickupText = addressText.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Using current location as pickup.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch current location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  PlacePrediction _pickBestPrediction(
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

  Future<void> _resolveTypedLocationInputs() async {
    final pickupText = _pickupController.text.trim();
    if (_pickupCoordinates == null &&
        _selectedPickupPlace == null &&
        pickupText.isNotEmpty) {
      final predictions =
          await PlacesService.getAutocompletePredictions(pickupText);
      if (predictions.isNotEmpty) {
        final bestMatch = _pickBestPrediction(pickupText, predictions);
        final coords =
            await PlacesService.getPlaceCoordinates(bestMatch.placeId);
        if (!mounted) return;
        if (coords != null) {
          setState(() {
            _selectedPickupPlace = bestMatch;
            _pickupCoordinates = coords;
            _resolvedPickupText = pickupText;
          });
        }
      }

      if (_pickupCoordinates == null) {
        final fallbackCoords = await _geocodeAddressText(pickupText);
        if (!mounted) return;
        if (fallbackCoords != null) {
          setState(() {
            _pickupCoordinates = fallbackCoords;
            _resolvedPickupText = pickupText;
          });
        }
      }
    }

    final destinationText = _destinationController.text.trim();
    if (_destinationCoordinates == null &&
        _selectedDestinationPlace == null &&
        destinationText.isNotEmpty) {
      final predictions =
          await PlacesService.getAutocompletePredictions(destinationText);
      if (predictions.isNotEmpty) {
        final bestMatch = _pickBestPrediction(destinationText, predictions);
        final coords =
            await PlacesService.getPlaceCoordinates(bestMatch.placeId);
        if (!mounted) return;
        if (coords != null) {
          setState(() {
            _selectedDestinationPlace = bestMatch;
            _destinationCoordinates = coords;
            _resolvedDestinationText = destinationText;
          });
        }
      }

      if (_destinationCoordinates == null) {
        final fallbackCoords = await _geocodeAddressText(destinationText);
        if (!mounted) return;
        if (fallbackCoords != null) {
          setState(() {
            _destinationCoordinates = fallbackCoords;
            _resolvedDestinationText = destinationText;
          });
        }
      }
    }
  }

  Future<Map<String, double>?> _geocodeAddressText(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      final serviceCoords = await PlacesService.getCoordinatesFromText(query);
      if (serviceCoords != null) {
        return serviceCoords;
      }
    } catch (_) {}

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return null;

      return {
        'lat': locations.first.latitude,
        'lng': locations.first.longitude,
      };
    } catch (_) {
      return null;
    }
  }

  void _searchFares() async {
    if (_formKey.currentState!.validate()) {
      await _resolveTypedLocationInputs();
      if (!mounted) return;

      // When the user types arbitrary text without selecting an autocomplete
      // suggestion, we won't have a placeId to resolve coordinates. Fail fast
      // with a clear message instead of silently proceeding.
      if (_pickupCoordinates == null && _selectedPickupPlace == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please select a pickup location from the suggestions.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }
      if (_destinationCoordinates == null &&
          _selectedDestinationPlace == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please select a destination from the suggestions.',
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      setState(() {
        _isCalculatingDistance = true;
      });

      double distance = 15.5;
      double duration = 1800;

      if ((_pickupCoordinates != null || _selectedPickupPlace != null) &&
          (_destinationCoordinates != null ||
              _selectedDestinationPlace != null)) {
        try {
          final pickupCoords = _pickupCoordinates ??
              await PlacesService.getPlaceCoordinates(
                  _selectedPickupPlace!.placeId);
          final destCoords = _destinationCoordinates ??
              await PlacesService.getPlaceCoordinates(
                _selectedDestinationPlace!.placeId,
              );

          if (pickupCoords != null && destCoords != null) {
            // Try OSRM for real road distance first.
            final osrm = await PlacesService.getRoadDistanceOSRM(
              pickupCoords['lat']!,
              pickupCoords['lng']!,
              destCoords['lat']!,
              destCoords['lng']!,
            );

            if (osrm != null) {
              distance = osrm['distance']!;   // already in km
              duration = osrm['duration']!;   // already in seconds
              debugPrint('✅ OSRM road distance: ${distance.toStringAsFixed(2)} km, '
                  '${(duration / 60).toStringAsFixed(0)} min');
            } else {
              // Fallback: Haversine × 1.35 road-correction factor
              final straightLine = _calculateDistance(
                pickupCoords['lat']!,
                pickupCoords['lng']!,
                destCoords['lat']!,
                destCoords['lng']!,
              );
              distance = straightLine * 1.35;
              duration = (distance / 28) * 3600; // ~28 km/h avg Indian city speed
              debugPrint('⚠️ OSRM unavailable. Haversine×1.35 = ${distance.toStringAsFixed(2)} km');
            }

            // Guard against absurdly large distances.
            final pickupText = _pickupController.text.trim();
            final destinationText = _destinationController.text.trim();
            final hasDetailedPickup = pickupText.contains(',');
            final hasDetailedDestination = destinationText.contains(',');
            if (distance > 100 &&
                (!hasDetailedPickup || !hasDetailedDestination)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Location seems too far for a local ride. Please choose a more specific pickup/destination from suggestions.',
                    ),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
              setState(() {
                _isCalculatingDistance = false;
              });
              return;
            }
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

      if (_pickupCoordinates != null) {
        pickupData = {
          'address': _pickupController.text,
          'lat': _pickupCoordinates!['lat'],
          'lng': _pickupCoordinates!['lng'],
        };
      } else if (_selectedPickupPlace != null) {
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

      if (_destinationCoordinates != null) {
        destinationData = {
          'address': _destinationController.text,
          'lat': _destinationCoordinates!['lat'],
          'lng': _destinationCoordinates!['lng'],
        };
      } else if (_selectedDestinationPlace != null) {
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
              content: const Text(
                  'Unable to get location coordinates. Please try again.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                                          onPlaceSelected: (place) async {
                                            setState(() {
                                              _selectedPickupPlace = place;
                                              _pickupCoordinates = null;
                                              _resolvedPickupText = null;
                                            });

                                            final coords = await PlacesService
                                                .getPlaceCoordinates(
                                              place.placeId,
                                            );
                                            if (!mounted) return;
                                            if (_pickupController.text.trim() !=
                                                place.description.trim()) {
                                              return;
                                            }
                                            if (coords == null) {
                                              ScaffoldMessenger.of(this.context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Could not fetch pickup coordinates. Try another suggestion.',
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFEF4444),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  margin:
                                                      const EdgeInsets.all(16),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _pickupCoordinates = coords;
                                              _resolvedPickupText =
                                                  _pickupController.text.trim();
                                            });
                                          },
                                        ),

                                        const SizedBox(height: 12),

                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _isFetchingCurrentLocation
                                                ? null
                                                : _useCurrentLocationForPickup,
                                            icon: _isFetchingCurrentLocation
                                                ? const SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.my_location_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                            label: Text(
                                              _isFetchingCurrentLocation
                                                  ? 'Fetching current location...'
                                                  : 'Use current location',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // Swap Button
                                        Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.swap_vert_rounded),
                                              color: Colors.white,
                                              iconSize: 28,
                                              onPressed: () {
                                                final temp =
                                                    _pickupController.text;
                                                _pickupController.text =
                                                    _destinationController.text;
                                                _destinationController.text =
                                                    temp;

                                                final tempPlace =
                                                    _selectedPickupPlace;
                                                _selectedPickupPlace =
                                                    _selectedDestinationPlace;
                                                _selectedDestinationPlace =
                                                    tempPlace;

                                                final tempCoords =
                                                    _pickupCoordinates;
                                                _pickupCoordinates =
                                                    _destinationCoordinates;
                                                _destinationCoordinates =
                                                    tempCoords;

                                                final tempResolvedText =
                                                    _resolvedPickupText;
                                                _resolvedPickupText =
                                                    _resolvedDestinationText;
                                                _resolvedDestinationText =
                                                    tempResolvedText;
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
                                          onPlaceSelected: (place) async {
                                            setState(() {
                                              _selectedDestinationPlace = place;
                                              _destinationCoordinates = null;
                                              _resolvedDestinationText = null;
                                            });

                                            final coords = await PlacesService
                                                .getPlaceCoordinates(
                                              place.placeId,
                                            );
                                            if (!mounted) return;
                                            if (_destinationController.text
                                                    .trim() !=
                                                place.description.trim()) {
                                              return;
                                            }
                                            if (coords == null) {
                                              ScaffoldMessenger.of(this.context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Could not fetch destination coordinates. Try another suggestion.',
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFEF4444),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  margin:
                                                      const EdgeInsets.all(16),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _destinationCoordinates = coords;
                                              _resolvedDestinationText =
                                                  _destinationController.text
                                                      .trim();
                                            });
                                          },
                                        ),

                                        const SizedBox(height: 32),

                                        // Search Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 60,
                                          child: ElevatedButton(
                                            onPressed: _isCalculatingDistance
                                                ? null
                                                : _searchFares,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  const Color(0xFF5B47ED),
                                              disabledBackgroundColor:
                                                  Colors.white.withOpacity(0.3),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                              shadowColor:
                                                  Colors.black.withOpacity(0.3),
                                            ),
                                            child: _isCalculatingDistance
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Color(0xFF5B47ED),
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Find Best Rides',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          size: 22),
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
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
