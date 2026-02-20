import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ramadan_cal_model.dart';
import '../services/ramadan_cal_service.dart';
import '../services/user_profile_service.dart';

final ramadhanCalendarServiceProvider = Provider<RamadhanCalendarService>((ref) {
  return RamadhanCalendarService(ref.read(firestoreProvider));
});

final ramadhanCalendarProvider =
StreamProvider.family<RamadhanCalendarConfig?, int>((ref, year) {
  return ref.watch(ramadhanCalendarServiceProvider).watchYear(year);
});