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

  Future<void> setSolat({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required String prayerKey,
    required bool value,
  }) async {
    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'solat': {
            '$day': {prayerKey: value},
          },
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> setFastingScore({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required double score,
  }) async {
    if (day < 1 || day > 30) {
      throw ArgumentError('day must be between 1 and 30');
    }
    if (score != 0.0 && score != 0.5 && score != 1.0) {
      throw ArgumentError('score must be 0.0, 0.5, or 1.0');
    }

    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'fasting': {'$day': score},
        }
      }
    }, SetOptions(merge: true));
  }
}