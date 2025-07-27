import 'package:flutter/material.dart';
import '../models/fare_estimate.dart';

class FareCard extends StatelessWidget {
  final FareEstimate estimate;
  final bool isLowest;
  final VoidCallback onBook;

  const FareCard({
    Key? key,
    required this.estimate,
    required this.isLowest,
    required this.onBook,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isLowest ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isLowest 
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isLowest
              ? LinearGradient(
                  colors: [Colors.green[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isLowest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BEST PRICE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isLowest) const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getServiceColor(estimate.id).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getServiceIcon(estimate.id),
                        color: _getServiceColor(estimate.id),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estimate.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            estimate.vehicleType,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${estimate.estimatedFare}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isLowest ? Colors.green[700] : Colors.black,
                          ),
                        ),
                        Text(
                          '${estimate.distance} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${estimate.eta} min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.route,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${estimate.duration} min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLowest 
                            ? Colors.green
                            : Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(String serviceId) {
    switch (serviceId.toLowerCase()) {
      case 'uber':
        return Colors.black;
      case 'ola':
        return Colors.green;
      case 'rapido':
        return Colors.yellow[700]!;
      case 'blinkit':
      case 'blusmart':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getServiceIcon(String serviceId) {
    switch (serviceId.toLowerCase()) {
      case 'uber':
        return Icons.directions_car;
      case 'ola':
        return Icons.local_taxi;
      case 'rapido':
        return Icons.motorcycle;
      case 'blinkit':
      case 'blusmart':
        return Icons.electric_car;
      default:
        return Icons.directions_car;
    }
  }
}
