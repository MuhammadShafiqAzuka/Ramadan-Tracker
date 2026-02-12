import 'package:flutter_riverpod/flutter_riverpod.dart';

// -----------------------------
// ✅ Daily Reminder (Riverpod 3)
// -----------------------------
final homeReminderProvider =
NotifierProvider<HomeReminderNotifier, String?>(HomeReminderNotifier.new);

class HomeReminderNotifier extends Notifier<String?> {
  @override
  String? build() => null; // dismissed iso date (YYYY-MM-DD)

  void dismissToday(String isoDate) => state = isoDate;

  bool isDismissed(String isoDate) => state == isoDate;
}
