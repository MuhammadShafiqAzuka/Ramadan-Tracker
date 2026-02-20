import 'package:intl/intl.dart';

class RamadhanCalendar {
  final DateTime startDate;
  final int days;

  RamadhanCalendar({required this.startDate, required this.days});

  DateTime dateForDay(int day) => startDate.add(Duration(days: day - 1));

  int autoDayFor(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final diff = today.difference(start).inDays + 1; // Day 1-based
    if (diff >= 1 && diff <= days) return diff;
    return 1;
  }

  String dayLabel(int day, {String locale = 'ms_MY'}) {
    return DateFormat('d MMM', locale).format(dateForDay(day));
  }

  String fullLabel(int day, {String locale = 'ms_MY'}) {
    return DateFormat('EEEE, d MMM yyyy', locale).format(dateForDay(day));
  }
}