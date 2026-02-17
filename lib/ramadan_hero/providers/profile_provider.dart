import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);

  // ✅ watch auth changes, not just currentUser once
  return auth.authStateChanges().switchMap((user) {
    final uid = user?.uid;
    if (uid == null) {
      return Stream<UserProfile?>.value(null);
    }

    final db = ref.watch(firestoreProvider);
    return db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromMap(uid, snap.data()!);
    });
  });
});