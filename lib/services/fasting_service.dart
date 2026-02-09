import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_profile_service.dart';

final fastingServiceProvider = Provider<FastingService>((ref) {
  return FastingService(ref.read(firestoreProvider));
});

class FastingService {
  final FirebaseFirestore _db;
  FastingService(this._db);

  DocumentReference<Map<String, dynamic>> _yearRef(String uid, int year) {
    return _db.collection('users').doc(uid).collection('ramadhan').doc('$year');
  }

  Stream<Map<String, dynamic>?> watchYear(String uid, int year) {
    return _yearRef(uid, year).snapshots().map((s) => s.data());
  }

  Future<void> setFastingDay({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required bool value,
  }) async {
    if (day < 1 || day > 30) {
      throw ArgumentError('day must be between 1 and 30');
    }

    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'fasting': {'$day': value},
        }
      }
    }, SetOptions(merge: true));
  }
}
