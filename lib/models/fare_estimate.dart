class FareEstimate {
  final String id;
  final String name;
  final String provider;
  final int estimatedFare;
  final int fareMin;
  final int fareMax;
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
    int? fareMin,
    int? fareMax,
    required this.eta,
    required this.surgeMultiplier,
    required this.vehicleType,
    required this.distance,
    required this.duration,
    this.capacity = 4,
  })  : fareMin = fareMin ?? estimatedFare,
        fareMax = fareMax ?? estimatedFare;

  bool get isBike {
    final type = vehicleType.toLowerCase();
    final service = name.toLowerCase();
    final p = provider.toLowerCase();
    return type.contains('bike') ||
        type.contains('moto') ||
        type.contains('two_wheeler') ||
        type.contains('scooter') ||
        service.contains('bike') ||
        service.contains('moto') ||
        (p == 'rapido' && !service.contains('auto') && !service.contains('cab'));
  }

  bool get isAuto {
    final type = vehicleType.toLowerCase();
    final service = name.toLowerCase();
    final p = provider.toLowerCase();
    return type.contains('auto') ||
        type.contains('rickshaw') ||
        service.contains('auto') ||
        service.contains('rickshaw') ||
        p.contains('namma yatri');
  }

  bool get isCab => !isBike && !isAuto;

  String get category {
    if (isBike) return 'Bikes';
    if (isAuto) return 'Autos';
    return 'Cabs';
  }

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double readDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

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

      if (type.contains('bike') ||
          serviceName.contains('bike') ||
          serviceName.contains('rapido')) {
        return 1; // Bikes
      } else if (type.contains('auto') || serviceName.contains('auto')) {
        return 3; // Auto rickshaw
      } else if (type.contains('xl') ||
          type.contains('suv') ||
          serviceName.contains('xl') ||
          serviceName.contains('suv')) {
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
      estimatedFare: readInt(json['estimatedFare'] ?? json['price']),
      fareMin:
          readInt(json['fareMin'] ?? json['estimatedFare'] ?? json['price']),
      fareMax:
          readInt(json['fareMax'] ?? json['estimatedFare'] ?? json['price']),
      eta: readInt(json['eta'] ?? 5),
      surgeMultiplier: readDouble(json['surgeMultiplier'] ?? 1.0),
      vehicleType: vehicleType,
      distance: readDouble(json['distance']),
      duration: readInt(json['duration']),
      capacity: readInt(json['capacity']) == 0
          ? getCapacity(vehicleType, name)
          : readInt(json['capacity']),
    );
  }
}
