class SavedWorkplace {
  final double lat;
  final double lng;
  final String name;

  const SavedWorkplace({
    required this.lat,
    required this.lng,
    required this.name,
  });

  factory SavedWorkplace.fromDynamic(Object? raw) {
    final map = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    final lat = ((map['lat'] ?? map['workplaceLat']) as num?)?.toDouble();
    final lng = ((map['lng'] ?? map['workplaceLng']) as num?)?.toDouble();
    if (lat == null || lng == null) {
      throw const FormatException('Invalid workplace coordinates');
    }

    final name = (map['name'] ?? map['workplaceName'] ?? '').toString();

    return SavedWorkplace(
      lat: lat,
      lng: lng,
      name: name,
    );
  }

  static SavedWorkplace? fromDynamicSafe(Object? raw) {
    if (raw is! Map) return null;
    try {
      return SavedWorkplace.fromDynamic(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lat': lat,
      'lng': lng,
      'name': name,
    };
  }
}
