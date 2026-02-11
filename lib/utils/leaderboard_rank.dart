import 'package:flutter/material.dart';

@immutable
class LeaderTier {
  final String label;
  final IconData icon;
  final int minScore; // inclusive
  final int? nextAt;  // next threshold (null if top)
  const LeaderTier({
    required this.label,
    required this.icon,
    required this.minScore,
    this.nextAt,
  });
}

@immutable
class NextTierInfo {
  final int remain;
  final LeaderTier nextTier;
  const NextTierInfo({required this.remain, required this.nextTier});
}

NextTierInfo? nextTierInfo(int markah) {
  final t = tierForMarkah(markah);
  if (t.nextAt == null) return null;

  final remain = (t.nextAt! - markah).clamp(0, 999999);
  final next = _tiers.firstWhere(
        (x) => x.minScore == t.nextAt,
    orElse: () => _tiers.last,
  );

  return NextTierInfo(remain: remain, nextTier: next);
}

/// Max per member = 180 (30 days * 6)
const _tiers = <LeaderTier>[
  LeaderTier(label: 'Pelatih',   icon: Icons.school_rounded,       minScore: 0,   nextAt: 45),
  LeaderTier(label: 'Wira',      icon: Icons.shield_rounded,       minScore: 45,  nextAt: 90),
  LeaderTier(label: 'Hero',      icon: Icons.emoji_events_rounded, minScore: 90,  nextAt: 135),
  LeaderTier(label: 'Legendary', icon: Icons.auto_awesome_rounded, minScore: 135, nextAt: null),
];

LeaderTier tierForMarkah(int markah) {
  for (var i = _tiers.length - 1; i >= 0; i--) {
    if (markah >= _tiers[i].minScore) return _tiers[i];
  }
  return _tiers.first;
}

double tierProgress(int markah) {
  final t = tierForMarkah(markah);
  if (t.nextAt == null) return 1.0;
  final span = (t.nextAt! - t.minScore).clamp(1, 999999);
  return ((markah - t.minScore) / span).clamp(0.0, 1.0);
}

String tierRemainText(int markah) {
  final t = tierForMarkah(markah);
  if (t.nextAt == null) return 'Max Rank';
  final remain = (t.nextAt! - markah).clamp(0, 999999);
  return '$remain lagi';
}

Color tierColor(ColorScheme cs, LeaderTier tier) {
  switch (tier.label) {
    case 'Pelatih':
      return cs.primary;
    case 'Wira':
      return const Color(0xFF3B82F6); // blue
    case 'Hero':
      return const Color(0xFF10B981); // green
    default:
      return const Color(0xFFA855F7); // purple (Legendary)
  }
}