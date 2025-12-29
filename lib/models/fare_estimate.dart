class FareEstimate {
  final String id;
  final String name;
  final String provider;
  final int estimatedFare;
  final int eta;
  final double surgeMultiplier;
  final String vehicleType;
  final double distance;
  final int duration;
  final int capacity;

  FareEstimate({
    required this.id,
    required this.name,
    required this.provider,
    required this.estimatedFare,
    required this.eta,
    required this.surgeMultiplier,
    required this.vehicleType,
    required this.distance,
    required this.duration,
    this.capacity = 4, // Default capacity
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    // Extract provider from the name or use a dedicated field
    String extractProvider(String name) {
      final lowerName = name.toLowerCase();
      if (lowerName.contains('uber')) return 'Uber';
      if (lowerName.contains('ola')) return 'Ola';
      if (lowerName.contains('rapido')) return 'Rapido';
      if (lowerName.contains('meru')) return 'Meru';
      return 'Unknown';
    }

    // Determine capacity based on vehicle type
    int getCapacity(String vehicleType, String name) {
      final type = vehicleType.toLowerCase();
      final serviceName = name.toLowerCase();
      
      if (type.contains('bike') || serviceName.contains('bike') || 
          serviceName.contains('rapido')) {
        return 1; // Bikes
      } else if (type.contains('auto') || serviceName.contains('auto')) {
        return 3; // Auto rickshaw
      } else if (type.contains('xl') || type.contains('suv') || 
                 serviceName.contains('xl') || serviceName.contains('suv')) {
        return 6; // XL/SUV
      } else if (type.contains('sedan') || serviceName.contains('sedan')) {
        return 4; // Sedan
      } else {
        return 4; // Default
      }
    }

    final name = json['name'] ?? '';
    final vehicleType = json['vehicleType'] ?? json['name'] ?? 'Car';
    
    return FareEstimate(
      id: json['id'] ?? json['name']?.toString().toLowerCase() ?? '',
      name: name,
      provider: json['provider'] ?? extractProvider(name),
      estimatedFare: json['estimatedFare'] ?? json['price'] ?? 0,
      eta: json['eta'] ?? 5,
      surgeMultiplier: (json['surgeMultiplier'] ?? 1.0).toDouble(),
      vehicleType: vehicleType,
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      capacity: json['capacity'] ?? getCapacity(vehicleType, name),
    );
  }
}