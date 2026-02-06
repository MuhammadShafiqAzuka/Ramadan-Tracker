enum PlanType { solo, five, nine }

extension PlanTypeX on PlanType {
  String get id => switch (this) {
    PlanType.solo => 'solo',
    PlanType.five => 'five',
    PlanType.nine => 'nine',
  };

  String get title => switch (this) {
    PlanType.solo => 'Solo',
    PlanType.five => 'Famili-5',
    PlanType.nine => 'Famili-9',
  };

  static PlanType fromId(String id) => switch (id) {
    'solo' => PlanType.solo,
    'five' => PlanType.five,
    'nine' => PlanType.nine,
    _ => PlanType.solo,
  };
}
