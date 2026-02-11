String isoDayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String formatTime12h(DateTime dt) {
  int hour = dt.hour;
  final minute = dt.minute;
  final isPm = hour >= 12;

  hour = hour % 12;
  if (hour == 0) hour = 12;

  final minuteStr = minute.toString().padLeft(2, '0');
  final suffix = isPm ? 'pm' : 'am';

  return '$hour.$minuteStr$suffix';
}
