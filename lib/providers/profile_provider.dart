import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;

  if (uid == null) {
    return const Stream<UserProfile?>.empty();
  }

  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(uid).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromMap(uid, snap.data()!);
  });
});
