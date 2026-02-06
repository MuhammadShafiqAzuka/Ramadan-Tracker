import 'plan_type.dart';

class UserProfile {
  final String uid;
  final String email;
  final PlanType planType;
  final List<String> parents;
  final List<String> children;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.planType,
    required this.parents,
    required this.children,
  });

  static UserProfile fromMap(String uid, Map<String, dynamic> data) {
    final email = (data['email'] ?? '') as String;
    final planId = (data['planType'] ?? 'solo') as String;

    final household = (data['household'] as Map<String, dynamic>?) ?? {};
    final parents = (household['parents'] as List?)?.cast<String>() ?? <String>[];
    final children =
        (household['children'] as List?)?.cast<String>() ?? <String>[];

    return UserProfile(
      uid: uid,
      email: email,
      planType: PlanTypeX.fromId(planId),
      parents: parents,
      children: children,
    );
  }
}