import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

class _HomeScreenModernState extends State<HomeScreenModern> {
  static const _ink = Color(0xFF1F2933);
  static const _yellow = Color(0xFFF6C744);
  static const _canvas = Color(0xFFF7F7F5);

  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PlacePrediction? _pickupPlace;
  PlacePrediction? _destinationPlace;
  Map<String, double>? _pickupCoordinates;
  Map<String, double>? _destinationCoordinates;
  bool _loadingLocation = false;
  bool _searching = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<Map<String, double>?> _geocode(String text) async {
    final result = await PlacesService.getCoordinatesFromText(text);
    if (result != null) return result;
    try {
      final locations = await locationFromAddress(text);
      if (locations.isEmpty) return null;
      return {
        'lat': locations.first.latitude,
        'lng': locations.first.longitude
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingLocation) return;
    setState(() => _loadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      var address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final places = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (places.isNotEmpty) {
          final place = places.first;
          final parts = [
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ]
              .where((value) => value != null && value.trim().isNotEmpty)
              .map((value) => value!)
              .toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _pickupController.text = address;
        _pickupPlace = null;
        _pickupCoordinates = {
          'lat': position.latitude,
          'lng': position.longitude
        };
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _swapLocations() {
    setState(() {
      final pickupText = _pickupController.text;
      final pickupPlace = _pickupPlace;
      final pickupCoordinates = _pickupCoordinates;
      _pickupController.text = _destinationController.text;
      _destinationController.text = pickupText;
      _pickupPlace = _destinationPlace;
      _destinationPlace = pickupPlace;
      _pickupCoordinates = _destinationCoordinates;
      _destinationCoordinates = pickupCoordinates;
    });
  }

  Future<void> _searchFares() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _searching = true);

    if (_pickupPlace == null) {
      _pickupCoordinates = await _geocode(_pickupController.text.trim());
    }
    if (_destinationPlace == null) {
      _destinationCoordinates =
          await _geocode(_destinationController.text.trim());
    }
    if (!mounted) return;

    if (_pickupCoordinates == null || _destinationCoordinates == null) {
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Select both locations from the suggestions and try again.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final pickup = {
      'address': _pickupController.text.trim(),
      'lat': _pickupCoordinates!['lat'],
      'lng': _pickupCoordinates!['lng'],
    };
    final destination = {
      'address': _destinationController.text.trim(),
      'lat': _destinationCoordinates!['lat'],
      'lng': _destinationCoordinates!['lng'],
    };

    final road = await PlacesService.getRoadDistanceOSRM(
      _pickupCoordinates!['lat']!,
      _pickupCoordinates!['lng']!,
      _destinationCoordinates!['lat']!,
      _destinationCoordinates!['lng']!,
    );
    double distance;
    double duration;
    if (road != null) {
      distance = road['distance']!;
      duration = road['duration']!;
    } else {
      distance = _calculateDistance(
            _pickupCoordinates!['lat']!,
            _pickupCoordinates!['lng']!,
            _destinationCoordinates!['lat']!,
            _destinationCoordinates!['lng']!,
          ) *
          1.35;
      duration = (distance / 28) * 3600;
    }
    if (!mounted) return;

    await Provider.of<FareProvider>(context, listen: false).getFareEstimates(
      pickup: pickup,
      destination: destination,
      distance: distance,
      duration: duration,
    );
    if (!mounted) return;
    setState(() => _searching = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreenModern(
          pickup: _pickupController.text.trim(),
          destination: _destinationController.text.trim(),
          pickupData: pickup,
          destinationData: destination,
        ),
      ),
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 20,
                vertical: 18,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isWide ? 620 : constraints.maxWidth),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: Colors.white,
                                size: 23),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FareFinder',
                                    style: TextStyle(
                                        color: _ink,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4)),
                                Text('Compare before you go',
                                    style: TextStyle(
                                        color: Color(0xFF7A828A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Where would you\nlike to go?',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 34,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Supported vehicle categories pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRideTypeChip(
                              icon: Icons.two_wheeler_rounded,
                              label: 'Bikes',
                              color: const Color(0xFFD97706),
                              bg: const Color(0xFFFEF3C7),
                            ),
                            const SizedBox(width: 8),
                            _buildRideTypeChip(
                              icon: Icons.electric_rickshaw_rounded,
                              label: 'Autos',
                              color: const Color(0xFF059669),
                              bg: const Color(0xFFD1FAE5),
                            ),
                            const SizedBox(width: 8),
                            _buildRideTypeChip(
                              icon: Icons.directions_car_filled_rounded,
                              label: 'Cabs',
                              color: const Color(0xFF4F46E5),
                              bg: const Color(0xFFEEF2FF),
                            ),
                            const SizedBox(width: 8),
                            _buildRideTypeChip(
                              icon: Icons.compare_arrows_rounded,
                              label: 'Live Fares',
                              color: _ink,
                              bg: const Color(0xFFF3F4F6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Location Input Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _locationField(
                                controller: _pickupController,
                                label: 'Pickup',
                                hint: 'Enter pickup location',
                                icon: Icons.my_location_rounded,
                                iconColor: const Color(0xFF10B981),
                                onSelected: (place) async {
                                  setState(() {
                                    _pickupPlace = place;
                                    _pickupCoordinates = null;
                                  });
                                  final coords =
                                      await PlacesService.getPlaceCoordinates(
                                          place.placeId);
                                  if (!mounted) return;
                                  setState(() => _pickupCoordinates = coords);
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _loadingLocation
                                      ? null
                                      : _useCurrentLocation,
                                  icon: _loadingLocation
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.near_me_rounded,
                                          size: 18),
                                  label: Text(_loadingLocation
                                      ? 'Getting location...'
                                      : 'Use current location'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 32,
                                    height: 1,
                                    color: const Color(0xFFE5E5E0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _locationField(
                                      controller: _destinationController,
                                      label: 'Destination',
                                      hint: 'Where to?',
                                      icon: Icons.location_on_rounded,
                                      iconColor: const Color(0xFFEF4444),
                                      onSelected: (place) async {
                                        setState(() {
                                          _destinationPlace = place;
                                          _destinationCoordinates = null;
                                        });
                                        final coords = await PlacesService
                                            .getPlaceCoordinates(place.placeId);
                                        if (!mounted) return;
                                        setState(() =>
                                            _destinationCoordinates = coords);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _swapLocations,
                                    tooltip: 'Swap locations',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      foregroundColor: _ink,
                                      minimumSize: const Size(46, 46),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.swap_vert_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _searching ? null : _searchFares,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _yellow,
                                    foregroundColor: _ink,
                                    disabledBackgroundColor:
                                        const Color(0xFFFDE68A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _searching
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _ink,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Find Best Rides',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 18, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Compare Uber, Ola, Rapido & Namma Yatri live',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRideTypeChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required Function(PlacePrediction) onSelected,
  }) {
    return LocationAutocompleteModern(
      controller: controller,
      labelText: label,
      hintText: hint,
      prefixIcon: icon,
      iconColor: iconColor,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Enter $label' : null,
      onPlaceSelected: onSelected,
    );
  }
}
