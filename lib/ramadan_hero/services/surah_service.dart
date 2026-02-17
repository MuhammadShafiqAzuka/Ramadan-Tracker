import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/utils/surah_list.dart';
import 'user_profile_service.dart';

final surahServiceProvider = Provider<SurahService>((ref) {
  return SurahService(ref.read(firestoreProvider));
});

class SurahService {
  final FirebaseFirestore _db;
  SurahService(this._db);

  DocumentReference<Map<String, dynamic>> _yearRef(String uid, int year) {
    return _db.collection('users').doc(uid).collection('ramadhan').doc('$year');
  }

  Stream<Map<String, dynamic>?> watchYear(String uid, int year) {
    return _yearRef(uid, year).snapshots().map((s) => s.data());
  }

  /// Structure:
  Future<void> toggleSurahDate({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int surah, // 1..114
    required String isoDate, // "YYYY-MM-DD"
    required bool value, // true = add date, false = remove date
  }) async {
    if (surah < 1 || surah > 114) throw ArgumentError('surah must be 1..114');

    final surahName = surahNames[surah - 1];

    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'surah': {
            '$surah': {
              'name': surahName,
              'lastRecitedAt': value ? FieldValue.serverTimestamp() : FieldValue.delete(),
              'dateRecited': value
                  ? FieldValue.arrayUnion([isoDate])
                  : FieldValue.arrayRemove([isoDate]),
            }
          },
        }
      }
    }, SetOptions(merge: true));
  }
}