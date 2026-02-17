import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile_service.dart';

final weightServiceProvider = Provider<WeightService>((ref) {
  return WeightService(ref.read(firestoreProvider));
});

class WeightService {
  final FirebaseFirestore _db;
  WeightService(this._db);

  DocumentReference<Map<String, dynamic>> _yearRef(String uid, int year) {
    return _db.collection('users').doc(uid).collection('ramadhan').doc('$year');
  }

  Stream<Map<String, dynamic>?> watchYear(String uid, int year) {
    return _yearRef(uid, year).snapshots().map((s) => s.data());
  }

  Future<void> setWeight({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required String isoDate, // YYYY-MM-DD
    required double weight,
  }) async {
    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'weight': {isoDate: weight},
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> setWeightCheckpoint({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required String key, // 'start' | 'end'
    required double weight,
  }) async {
    assert(key == 'start' || key == 'end');

    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'weightCheckpoint': {key: weight},
          'weightCheckpointAt': {key: FieldValue.serverTimestamp()},
        }
      }
    }, SetOptions(merge: true));
  }
}
