class FareEstimate {
  final String id;
  final String name;
  final int estimatedFare;
  final int eta;
  final double surgeMultiplier;
  final String vehicleType;
  final double distance;
  final int duration;

  FareEstimate({
    required this.id,
    required this.name,
    required this.estimatedFare,
    required this.eta,
    required this.surgeMultiplier,
    required this.vehicleType,
    required this.distance,
    required this.duration,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      id: json['id'] ?? json['name']?.toString().toLowerCase() ?? '',
      name: json['name'] ?? '',
      estimatedFare: json['estimatedFare'] ?? json['price'] ?? 0,
      eta: json['eta'] ?? 5,
      surgeMultiplier: (json['surgeMultiplier'] ?? 1.0).toDouble(),
      vehicleType: json['vehicleType'] ?? json['name'] ?? 'Car',
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
    );
  }
}