class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({
    required this.description,
    required this.placeId,
  });

  // This maps the Google/Node.js response to your Flutter object
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
    );
  }
}