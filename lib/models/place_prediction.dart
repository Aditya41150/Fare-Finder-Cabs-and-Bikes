class PlacePrediction {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.description,
    required this.placeId,
    String? mainText,
    String? secondaryText,
  })  : mainText = mainText ?? _extractMainText(description),
        secondaryText = secondaryText ?? _extractSecondaryText(description);

  // Extract main text (first part before comma)
  static String _extractMainText(String description) {
    final parts = description.split(',');
    return parts.isNotEmpty ? parts[0].trim() : description;
  }

  // Extract secondary text (everything after first comma)
  static String _extractSecondaryText(String description) {
    final parts = description.split(',');
    if (parts.length > 1) {
      return parts.sublist(1).join(',').trim();
    }
    return '';
  }

  // This maps the Google/Node.js response to your Flutter object
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final description = json['description'] ?? '';
    final structuredFormatting = json['structured_formatting'];
    
    return PlacePrediction(
      description: description,
      placeId: json['place_id'] ?? '',
      mainText: structuredFormatting?['main_text'] ?? _extractMainText(description),
      secondaryText: structuredFormatting?['secondary_text'] ?? _extractSecondaryText(description),
    );
  }
}