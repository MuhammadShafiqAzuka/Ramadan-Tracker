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

  void _validateDay(int day) {
    if (day < 1 || day > 30) {
      throw ArgumentError('day must be between 1 and 30');
    }
  }

  Map<String, dynamic> _basePayload({
    required int year,
    required String memberId,
    required String memberName,
    required Map<String, dynamic> memberData,
  }) {
    return {
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          ...memberData,
        }
      }
    };
  }

  // ----------------------------
  // Existing methods (kept)
  // ----------------------------
  Future<void> setFastingDay({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required bool value,
  }) async {
    _validateDay(day);

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'fasting': {'$day': value},
        },
      ),
      SetOptions(merge: true),
    );
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
    _validateDay(day);

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'solat': {
            '$day': {prayerKey: value},
          },
        },
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> setFastingScore({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required double score,
  }) async {
    _validateDay(day);
    if (score != 0.0 && score != 0.5 && score != 1.0) {
      throw ArgumentError('score must be 0.0, 0.5, or 1.0');
    }

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'fasting': {'$day': score},
        },
      ),
      SetOptions(merge: true),
    );
  }

  // ----------------------------
  // New: Tarawih (8 / 12)
  // ----------------------------
  Future<void> setTarawihRakaat({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required int rakaat, // 8 or 12
  }) async {
    _validateDay(day);
    if (rakaat != 8 && rakaat != 20) {
      throw ArgumentError('rakaat must be 8 or 20');
    }

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'tarawih': {'$day': rakaat},
        },
      ),
      SetOptions(merge: true),
    );
  }

  // ----------------------------
  // New: Sedekah (true / false)
  // ----------------------------
  Future<void> setSedekah({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required bool value,
  }) async {
    _validateDay(day);

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'sedekah': {'$day': value},
        },
      ),
      SetOptions(merge: true),
    );
  }

  // ----------------------------
  // New: Sahur (bangun = true/false)
  // ----------------------------
  Future<void> setSahur({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required bool value,
  }) async {
    _validateDay(day);

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'sahur': {'$day': value},
        },
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> setFastingNotFastingWithReason({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required String reason,
  }) async {
    _validateDay(day);

    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('reason cannot be empty');
    }

    await _yearRef(uid, year).set(
      _basePayload(
        year: year,
        memberId: memberId,
        memberName: memberName,
        memberData: {
          'fasting': {'$day': 0.0},
          'fastingReason': {'$day': trimmed},
        },
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> clearFastingReason({
    required String uid,
    required int year,
    required String memberId,
    required int day,
  }) async {
    _validateDay(day);

    await _yearRef(uid, year).set({
      'members': {
        memberId: {
          'fastingReason': {'$day': FieldValue.delete()},
        }
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setFidyahPaid({
    required String uid,
    required int year,
    required String memberId,
    required String memberName,
    required int day,
    required bool paid,
  }) async {
    _validateDay(day);

    await _yearRef(uid, year).set({
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
      'members': {
        memberId: {
          'name': memberName,
          'fidyahPaid': {'$day': paid},
        }
      }
    }, SetOptions(merge: true));
  }
}