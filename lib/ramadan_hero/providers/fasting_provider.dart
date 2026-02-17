import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fasting_service.dart';

final ramadhanYearProvider = StreamProvider.family<Map<String, dynamic>?, ({String uid, int year})>(
      (ref, args) {
    final service = ref.watch(fastingServiceProvider);
    return service.watchYear(args.uid, args.year);
  },
);