class FareEstimate {
  final String id;
  final String name;
  final int estimatedFare;
  final int eta;
  final String vehicleType;
  final String distance;
  final int duration;

  FareEstimate({
    required this.id,
    required this.name,
    required this.estimatedFare,
    required this.eta,
    required this.vehicleType,
    required this.distance,
    required this.duration,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      estimatedFare: json['estimatedFare'] ?? 0,
      eta: json['eta'] ?? 0,
      vehicleType: json['vehicleType'] ?? '',
      distance: json['distance'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'estimatedFare': estimatedFare,
      'eta': eta,
      'vehicleType': vehicleType,
      'distance': distance,
      'duration': duration,
    };
  }
}
