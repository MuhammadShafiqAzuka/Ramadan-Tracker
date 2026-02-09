import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile_service.dart';

final quranServiceProvider = Provider<QuranService>((ref) {
  return QuranService(ref.read(firestoreProvider));
});

class QuranService {
  final FirebaseFirestore _db;
  QuranService(this._db);

  DocumentReference<Map<String, dynamic>> _yearRef(String uid, int year) {
    return _db.collection('users').doc(uid).collection('ramadhan').doc('$year');
  }

  Stream<Map<String, dynamic>?> watchYear(String uid, int year) {
    return _yearRef(uid, year).snapshots().map((s) => s.data());
  }

  Future<void> setJuz({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int juz, // 1..30
    required bool value,
  }) async {
    if (juz < 1 || juz > 30) throw ArgumentError('juz must be 1..30');

    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'juz': {'$juz': value},
        }
      }
    }, SetOptions(merge: true));
  }
}
