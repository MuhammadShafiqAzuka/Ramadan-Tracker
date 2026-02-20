import 'package:cloud_firestore/cloud_firestore.dart';

class RamadhanCalendarConfig {
  final int year;
  final DateTime startDate;
  final int days;

  const RamadhanCalendarConfig({
    required this.year,
    required this.startDate,
    required this.days,
  });

  factory RamadhanCalendarConfig.fromMap(Map<String, dynamic> map) {
    final ts = map['startDate'];
    final start = (ts is Timestamp) ? ts.toDate() : DateTime.parse(ts.toString());

    return RamadhanCalendarConfig(
      year: (map['year'] as num).toInt(),
      startDate: DateTime(start.year, start.month, start.day),
      days: ((map['days'] ?? 30) as num).toInt(),
    );
  }
}