import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> destination;

  const MapScreen({super.key, required this.pickup, required this.destination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  double? distance;
  int? duration;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  void _calculateDistance() {
    final lat1 = widget.pickup['lat'];
    final lng1 = widget.pickup['lng'];
    final lat2 = widget.destination['lat'];
    final lng2 = widget.destination['lng'];

    const earthRadius = 6371.0; // km
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    distance = earthRadius * c;
    duration = ((distance! / 30) * 60).round(); // Assuming 30 km/h average speed
  }

  @override
  Widget build(BuildContext context) {
    final LatLng pickupLatLng = LatLng(
      widget.pickup['lat'],
      widget.pickup['lng'],
    );
    final LatLng destLatLng = LatLng(
      widget.destination['lat'],
      widget.destination['lng'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pickupLatLng, zoom: 14),
            onMapCreated: (controller) {
              mapController = controller;
              _zoomToFit(pickupLatLng, destLatLng);
            },
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickupLatLng,
                infoWindow: InfoWindow(
                  title: 'Pickup',
                  snippet: widget.pickup['address'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: destLatLng,
                infoWindow: InfoWindow(
                  title: 'Destination',
                  snippet: widget.destination['address'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
          ),

          // Route Info Card at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Route Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            Icons.straighten,
                            'Distance',
                            distance != null
                                ? '${distance!.toStringAsFixed(1)} km'
                                : 'Calculating...',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.access_time,
                            'Duration',
                            duration != null
                                ? '$duration min'
                                : 'Calculating...',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Continue Button at the bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                // Close map screen and return to show results
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Continue to Fare Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _zoomToFit(LatLng p1, LatLng p2) {
    LatLngBounds bounds;
    if (p1.latitude > p2.latitude) {
      bounds = LatLngBounds(southwest: p2, northeast: p1);
    } else {
      bounds = LatLngBounds(southwest: p1, northeast: p2);
    }
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }
}
