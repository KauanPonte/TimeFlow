class TimeEntry {
  final DateTime dateTime;
  final String type; // entrada | saida

  TimeEntry({
    required this.dateTime,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'type': type,
    };
  }

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      dateTime: DateTime.parse(map['dateTime']),
      type: map['type'],
    );
  }
}
