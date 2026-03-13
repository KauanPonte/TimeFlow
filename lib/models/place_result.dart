class PlaceResult {
  final String displayName;
  final String shortName;
  final double lat;
  final double lng;

  const PlaceResult({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lng,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    final parts = displayName.split(', ');
    final shortName = parts.take(2).join(', ');

    return PlaceResult(
      displayName: displayName,
      shortName: shortName,
      lat: double.tryParse(json['lat'] as String? ?? '0') ?? 0,
      lng: double.tryParse(json['lon'] as String? ?? '0') ?? 0,
    );
  }
}
