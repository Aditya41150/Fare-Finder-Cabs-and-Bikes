class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String pickup;
  final String destination;
  final int fare;
  final String status;
  final String bookingTime;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.pickup,
    required this.destination,
    required this.fare,
    required this.status,
    required this.bookingTime,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      pickup: json['pickup'] ?? '',
      destination: json['destination'] ?? '',
      fare: json['fare'] ?? 0,
      status: json['status'] ?? '',
      bookingTime: json['bookingTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'pickup': pickup,
      'destination': destination,
      'fare': fare,
      'status': status,
      'bookingTime': bookingTime,
    };
  }
}
