
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_type.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(ref.read(firestoreProvider));
});

class UserProfileService {
  final FirebaseFirestore _db;
  UserProfileService(this._db);

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required PlanType planType,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'planType': planType.id,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveHousehold({
    required String uid,
    required PlanType planType,
    required List<String> parents,
    required List<String> children,
  }) async {
    final normalizedParents = _clean(parents);
    final normalizedChildren = _clean(children);

    await _db.collection('users').doc(uid).set({
      'household': {
        'planType': planType.id,
        'parents': normalizedParents,
        'children': normalizedChildren,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  List<String> _clean(List<String> v) =>
      v.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}