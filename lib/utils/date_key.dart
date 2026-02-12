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

final reminders = <String>[
  'Jangan lupa berniat puasa bila bangun sahur 🌙\n\nNawaitu shauma ghadin ‘an adā’i fardhi syahri Ramadhāna hādzihis sanati lillāhi ta‘ālā.',
  'Bismillah. Sedikit tetapi konsisten itu paling dicintai 😊',
  'Ingat solat awal waktu—mudahkan urusan hari ini ✨',
  'Semoga Allah terima amalan kita hari ini. Aamiin 🤲',
  'Kalau terlepas rekod, boleh isi semula bila ingat 👍',
];

String isoTodayKey(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
