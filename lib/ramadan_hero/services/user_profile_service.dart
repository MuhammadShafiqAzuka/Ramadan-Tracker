
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

  // ✅ new method name + better parameters
  Future<void> saveSetup({
    required String uid,
    String? ownerName, // solo
    List<String>? parents, // five/nine
    List<String>? children, // five/nine
  }) async {
    final normalizedOwner = ownerName?.trim();
    final normalizedParents = _clean(parents ?? const []);
    final normalizedChildren = _clean(children ?? const []);

    final household = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (normalizedOwner != null && normalizedOwner.isNotEmpty) {
      household['ownerName'] = normalizedOwner;
    }

    if (normalizedParents.isNotEmpty) {
      household['parents'] = normalizedParents;
    }

    if (normalizedChildren.isNotEmpty) {
      household['children'] = normalizedChildren;
    }

    await _db.collection('users').doc(uid).set({
      'household': household,
    }, SetOptions(merge: true));
  }

  List<String> _clean(List<String> v) =>
      v.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}