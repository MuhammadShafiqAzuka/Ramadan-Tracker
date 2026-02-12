import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:ramadhan_hero/widgets/theme_toggle.dart';
import '../providers/home_reminder.dart';
import '../utils/date_key.dart';
import '../utils/leaderboard_rank.dart';
import '../utils/tw.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BreezeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;

  const BreezeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cs.primary.withOpacity(0.10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class BreezeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const BreezeCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).cardColor,
      ),
      child: child,
    );
  }
}

class BreezePill extends StatelessWidget {
  final String text;
  final IconData? icon;

  const BreezePill({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: cs.primary.withOpacity(0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
          ],
          Text(text, style: TextStyle(fontSize: Tw.s2, fontWeight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }
}

class BreezeProgressBlock extends StatelessWidget {
  final String title;
  final double value; // 0..1
  final String rightText;
  final String? subtitle;

  const BreezeProgressBlock({
    super.key,
    required this.title,
    required this.value,
    required this.rightText,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: Tw.s2)),
              const Spacer(),
              Text(rightText, style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: Tw.s2)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(fontSize: Tw.s2, color: Theme.of(context).hintColor)),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class BreezeMemberSelector extends StatelessWidget {
  final List<({String id, String name})> members;
  final String? value;
  final ValueChanged<String?> onChanged;

  const BreezeMemberSelector({
    super.key,
    required this.members,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BreezeCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text('Ahli', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(
                labelText: 'Pilih ahli keluarga',
              ),
              items: [
                for (final mem in members)
                  DropdownMenuItem(value: mem.id, child: Text(mem.name)),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class BreezeToggleChip extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  final double? width; // optional fixed width
  final IconData? icon; // optional

  const BreezeToggleChip({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = Theme.of(context).hintColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: checked ? cs.primary.withOpacity(0.10) : null,
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            // Heuristics: if chip is narrow, reduce what we show.
            final w = c.maxWidth.isFinite ? c.maxWidth : (width ?? 9999);
            final showLeftIcon = icon != null && w >= 86;
            final showRightIcon = w >= 74;

            return ClipRect(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max, // ✅ fill available width
                children: [
                  if (showLeftIcon) ...[
                    Icon(icon, size: 16, color: checked ? cs.primary : hint),
                    const SizedBox(width: 8),
                  ],

                  // ✅ label can shrink without overflow
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: Tw.s2,
                        color: checked ? cs.primary : null,
                      ),
                    ),
                  ),

                  if (showRightIcon) ...[
                    const SizedBox(width: 8),
                    Icon(
                      checked ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: checked ? cs.primary : hint,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BreezeWebScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onLogout;

  const BreezeWebScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Tw.darkBorder : Tw.slate200;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Breeze-like small icon control area
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
              color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
            ),
            child: const ThemeToggle(),
          ),
          if (onLogout != null)
            TextButton(
              onPressed: () async => context.go("/home"),
              child: const Text('Kembali'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: body,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  const SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cs.primary.withOpacity(0.10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: Tw.s2, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: Tw.s2, color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;

  const Pill({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: cs.primary.withOpacity(0.06),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
          ],
          Text(text, style: TextStyle(fontSize: Tw.s2, fontWeight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }
}

class BreezeProgressCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? footer;
  final String badgeText;
  final IconData icon;
  final VoidCallback onTap;

  /// Optional (0..1). If null => no bar (e.g. Surah Today).
  final double? progress;

  /// Optional right-side value (e.g. "62%")
  final String? valueText;

  /// Optional small pill on the right side (e.g. "+0.6 kg")
  final String? trendText;

  /// Optional trend icon (up/down/remove)
  final IconData? trendIcon;

  const BreezeProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.onTap,
    this.footer,
    this.progress,
    this.valueText,
    this.trendText,
    this.trendIcon,
  });

  @override
  State<BreezeProgressCard> createState() => _BreezeProgressCardState();
}

class _BreezeProgressCardState extends State<BreezeProgressCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = MediaQuery.of(context).size.width < 480;

    final border = isDark ? Tw.darkBorder : Tw.slate200;
    final bg = isDark ? Tw.darkCard : Tw.white;
    final sub = isDark ? Tw.darkSubtext : Tw.slate700;

    Widget pill(
        String text, {
          IconData? icon,
          Color? textColor,
          Color? iconColor,
          Color? bgColor,
        }) {
      final _bg = bgColor ?? cs.primary.withOpacity(isDark ? 0.10 : 0.06);
      final _tc = textColor ?? cs.primary;
      final _ic = iconColor ?? cs.primary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
          color: _bg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: _ic),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: Tw.s2,
                fontWeight: FontWeight.w800,
                color: _tc,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    // subtle hover lift for web
    final shadow = (!isDark && _hover) ? Tw.shadowMd : const <BoxShadow>[];

    // progress helpers
    final p = widget.progress?.clamp(0.0, 1.0);
    final showProgress = p != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          color: bg,
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: cs.primary.withOpacity(isDark ? 0.14 : 0.10),
                          border: Border.all(color: border),
                        ),
                        child: Icon(widget.icon, color: cs.primary, size: 20),
                      ),
                      SizedBox(width: isPhone ? 6 : 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: Tw.s2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      pill(widget.badgeText),
                    ],
                  ),

                  SizedBox(height: isPhone ? 14 : 22),

                  // Subtitle (kept neat)
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tw.s2,
                      color: sub,
                      height: 1.25,
                    ),
                  ),

                  // Progress row
                  if (showProgress) ...[
                    SizedBox(height: isPhone ? 8 : 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: p,
                              minHeight: 8,
                              backgroundColor:
                              (isDark ? Tw.darkBorder : Tw.slate200).withOpacity(0.55),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (widget.valueText != null)
                          Text(
                            widget.valueText!,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                              fontSize: Tw.s2
                            ),
                          ),
                      ],
                    ),
                  ],

                  SizedBox(height: isPhone ? 12 : 15),

                  // Footer row (footer + optional trend pill + chevron)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.footer ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Tw.s2,
                            color: sub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.trendText != null) ...[
                        const SizedBox(width: 10),
                        pill(
                          widget.trendText!,
                          icon: widget.trendIcon,
                          // neutral pill, not too loud
                          bgColor: cs.primary.withOpacity(isDark ? 0.10 : 0.06),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BreezeStreaksCard extends StatelessWidget {
  final List<({String id, String name, int streak})> streakRows;
  final int maxDays;

  /// ✅ NEW: allow hiding "Top: X hari"
  final bool showTopPill;

  const BreezeStreaksCard({
    super.key,
    required this.streakRows,
    required this.maxDays,
    this.showTopPill = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final top = streakRows.isNotEmpty ? streakRows.first.streak : 0;

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(text: 'Top: $top hari', icon: Icons.local_fire_department_rounded),
              const Spacer(),
              Text(
                '${streakRows.length} ahli',
                style: TextStyle(fontSize: Tw.s2, color: Theme.of(context).hintColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (streakRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Tiada streaks lagi.', style: TextStyle(color: Theme.of(context).hintColor)),
            )
          else
            ...List.generate(streakRows.length, (i) {
              final r = streakRows[i];
              final pct = (r.streak / maxDays).clamp(0.0, 1.0);
              final isTop = r.streak == top && top > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).hintColor,
                          fontSize: Tw.s2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: Tw.s2),
                                ),
                              ),
                              if (showTopPill && isTop) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: cs.primary.withOpacity(0.10),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Text(
                                    'Top',
                                    style: TextStyle(
                                      fontSize: Tw.s2,
                                      fontWeight: FontWeight.w900,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 66,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        color: cs.primary.withOpacity(0.06),
                      ),
                      child: Text(
                        '${r.streak}',
                        style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: Tw.s2),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class BreezeDayChips extends StatelessWidget {
  final int membersCount;
  final List<int> donePerDay;

  const BreezeDayChips({required this.membersCount, required this.donePerDay});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 30,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final day = i + 1;
          final done = donePerDay[i];
          final pct = membersCount == 0 ? 0.0 : (done / membersCount).clamp(0.0, 1.0);

          // Breeze-ish: subtle fill that increases with pct (still neutral)
          final fill = 0.06 + (0.16 * pct);

          return Container(
            width: 94,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: cs.primary.withOpacity(fill),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hari $day', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '$done / $membersCount',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BreezePodium extends StatelessWidget {
  final List<({String id, String name, int fasting, int juz, int surah})> top3;

  const BreezePodium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    final second = top3.length >= 2 ? top3[1] : null;
    final first = top3.isNotEmpty ? top3[0] : null;
    final third = top3.length >= 3 ? top3[2] : null;
    final isPhone = MediaQuery.of(context).size.width < 480;

    Widget box({required int rank, required ({String id, String name, int fasting, int juz, int surah}) row}) {
      final ratio = switch (rank) {
        1 => isPhone ? 1.35 : 1.7, // tallest
        2 => isPhone ? 1.35 : 1.7,
        _ => isPhone ? 1.35 : 1.7, // shortest
      };

      return AspectRatio(
        aspectRatio: ratio,
        child: BreezePodiumCard(rank: rank, row: row),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = isPhone || c.maxWidth < 560;

        if (stacked) {
          return Column(
            children: [
              if (first != null) box(rank: 1, row: first),
              const SizedBox(height: 10),
              if (second != null) box(rank: 2, row: second),
              const SizedBox(height: 10),
              if (third != null) box(rank: 3, row: third),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: second != null ? box(rank: 2, row: second) : const SizedBox()),
            const SizedBox(width: 10),
            Expanded(child: first != null ? box(rank: 1, row: first) : const SizedBox()),
            const SizedBox(width: 10),
            Expanded(child: third != null ? box(rank: 3, row: third) : const SizedBox()),
          ],
        );
      },
    );
  }
}

class BreezePodiumCard extends StatelessWidget {
  final int rank;
  final ({String id, String name, int fasting, int juz, int surah}) row;

  const BreezePodiumCard({
    super.key,
    required this.rank,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPhone = MediaQuery.of(context).size.width < 480;

    final markah = row.fasting + row.juz + row.surah;

    final tier = tierForMarkah(markah);
    final p = tierProgress(markah);

    Color medalColor(ColorScheme cs, int rank) {
      return switch (rank) {
        1 => const Color(0xFFD4AF37), // gold
        2 => const Color(0xFFC0C0C0), // silver
        _ => const Color(0xFFCD7F32), // bronze
      };
    }

    final medalIcon = switch (rank) {
      1 => Icons.emoji_events_rounded,
      2 => Icons.workspace_premium_rounded,
      _ => Icons.military_tech_rounded,
    };

    final medal = medalColor(cs, rank);
    final info = nextTierInfo(markah);

    Widget tierPill({bool compact = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: medal.withOpacity(0.4)),
          color: medal.withOpacity(0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tier.icon, size: compact ? 12 : 14, color: medal),
            const SizedBox(width: 6),
            Text(
              tier.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tw.s2,
                fontWeight: FontWeight.w900,
                color: medal,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        // Heuristic: podium cards have very constrained height.
        // Only show the progress bar if there is enough height.
        final showProgress = tier.nextAt != null;
        final isTight = c.maxHeight < 300;
        final border = Theme.of(context).dividerColor;
        final medalBorder = Color.alphaBlend(medal.withOpacity(0.18), border);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: medalBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                medal.withOpacity(rank == 1 ? 0.14 : 0.10),
                Theme.of(context).cardColor,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  Icon(medalIcon, color: medal),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      color: medal.withOpacity(0.14),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: medal,
                        fontSize: Tw.s2,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isPhone ? 1 : 5),

              // Tier pill
              Align(
                alignment: Alignment.centerLeft,
                child: tierPill(compact: isTight),
              ),

              SizedBox(height: isPhone ? 10 : 12),

              // Main content - make it flexible and safe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: Tw.s2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Markah $markah • Puasa & Solat ${row.fasting} • Juzuk ${row.juz} • Surah ${row.surah}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Tw.s2,
                        color: Theme.of(context).hintColor,
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: isPhone ? 13 : 15),

                    if (showProgress) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: p,
                          valueColor: AlwaysStoppedAnimation<Color>(medal),
                          minHeight: 8,
                          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.35),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (info != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: medal.withOpacity(0.4)),
                            color: medal.withOpacity(0.12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(info.nextTier.icon, size: 14, color: medal),
                              const SizedBox(width: 6),
                              Text(
                                info.nextTier.label.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: medal,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${info.remain} point lagi',
                                style: TextStyle(
                                  fontSize: Tw.s2,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'MAX RANK',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: medal,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BreezeLeaderboardCard extends StatelessWidget {
  final List<({String id, String name, int fasting, int juz, int surah})> leaderboard;

  const BreezeLeaderboardCard({super.key, required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.hintColor;

    if (leaderboard.isEmpty) {
      return BreezeCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'No data yet — start ticking trackers 😊',
            style: TextStyle(color: hint),
          ),
        ),
      );
    }

    final isSolo = leaderboard.length <= 1;
    final top3 = leaderboard.take(3).toList();
    final rest = leaderboard.length > 3 ? leaderboard.sublist(3) : const [];

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSolo) ...[
            // ✅ SOLO header
            Text(
              'Progress Anda',
              style: TextStyle(fontWeight: FontWeight.w900, color: hint),
            ),
            const SizedBox(height: 10),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 10),

            // ✅ Solo tile (no rank badge)
            Builder(builder: (_) {
              final r = leaderboard.first;
              final score = r.fasting + r.juz + r.surah;
              return BreezeLeaderboardTile(
                rank: 1,
                name: r.name,
                fasting: r.fasting,
                juz: r.juz,
                surah: r.surah,
                score: score,
                showRankBadge: false, // ✅ hide #1
              );
            }),
          ]
          else ...[
            // ✅ FAMILY podium
            if (top3.isNotEmpty) ...[
              BreezePodium(top3: top3),
              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    'Kedudukan seterusnya',
                    style: TextStyle(fontWeight: FontWeight.w900, color: hint),
                  ),
                  const Spacer(),
                  Text('${rest.length} ahli', style: TextStyle(color: hint)),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 10),
            ],

            // ✅ rest list (rank 4+)
            ...List.generate(rest.length, (i) {
              final r = rest[i];
              final rank = i + 4;
              final score = r.fasting + r.juz + r.surah;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: BreezeLeaderboardTile(
                  rank: rank,
                  name: r.name,
                  fasting: r.fasting,
                  juz: r.juz,
                  surah: r.surah,
                  score: score,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class BreezeLeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final int fasting;
  final int juz;
  final int surah;
  final int score;

  final bool showRankBadge;

  const BreezeLeaderboardTile({
    super.key,
    required this.rank,
    required this.name,
    required this.fasting,
    required this.juz,
    required this.surah,
    required this.score,
    this.showRankBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hint = theme.hintColor;
    final border = theme.dividerColor;

    final isPhone = MediaQuery.of(context).size.width < 480;

    final tier = tierForMarkah(score);
    final p = tierProgress(score);
    final info = nextTierInfo(score);

    // You already have this helper in your codebase.
    // It should return a Color for each tier.
    final tc = tierColor(cs, tier);

    Widget pill({
      required String text,
      required IconData icon,
      required Color color,
      String? suffix,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.35)),
          color: color.withOpacity(0.10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              text.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: Tw.s2,
                color: color,
                height: 1.0,
                letterSpacing: 0.5,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 8),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: Tw.s2,
                  color: hint,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget rankBadge() {
      // Slightly nicer: if rank is 4+, use a softer neutral badge.
      final bg = cs.primary.withOpacity(rank <= 3 ? 0.08 : 0.05);

      return Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          color: bg,
        ),
        child: Text(
          '$rank',
          style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary),
        ),
      );
    }

    Widget progressBlock() {
      if (tier.nextAt == null) {
        return pill(
          text: tier.label,
          icon: tier.icon,
          color: tc,
          suffix: 'Max',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(tc),
              backgroundColor: border.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 8),
          if (info != null)
            pill(
              text: info.nextTier.label,
              icon: info.nextTier.icon,
              color: tc,
              suffix: '${info.remain} point lagi',
            ),
        ],
      );
    }

    // Content (name, tier, breakdown, progress)
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 10),
            pill(text: tier.label, icon: tier.icon, color: tc),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Puasa & Solat $fasting • Juzuk $juz • Surah $surah',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: Tw.s2, color: hint, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        progressBlock(),
      ],
    );

    // ✅ Phone: move score to a full-width bar at bottom (cleaner)
    Widget scoreBar() {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          color: tc.withOpacity(0.06),
        ),
        child: Row(
          children: [
            Text(
              'Markah',
              style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: tc,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Desktop: score on right
    Widget scoreBox() {
      return Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          color: tc.withOpacity(0.10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Markah',
              style: TextStyle(fontSize: 11, color: hint, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '$score',
              style: TextStyle(fontWeight: FontWeight.w900, color: tc, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: isPhone
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showRankBadge) ...[
                rankBadge(),
                const SizedBox(width: 12),
              ],
              Expanded(child: content),
            ],
          ),
          scoreBar(),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRankBadge) ...[
            rankBadge(),
            const SizedBox(width: 12),
          ],
          Expanded(child: content),
          const SizedBox(width: 12),
          scoreBox(),
        ],
      ),
    );
  }
}

class BreezeTinyStat extends StatelessWidget {
  final String label;
  final int value;

  const BreezeTinyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class MiniDayChip extends StatelessWidget {
  final String label;
  final String subtitle;

  const MiniDayChip({super.key, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class WheelToHorizontalScroll extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const WheelToHorizontalScroll({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller ?? ScrollController();

    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          // Convert vertical wheel to horizontal scroll.
          final newOffset = (c.offset + signal.scrollDelta.dy).clamp(
            c.position.minScrollExtent,
            c.position.maxScrollExtent,
          );
          c.jumpTo(newOffset);
        }
      },
      child: Scrollbar(
        controller: c,
        thumbVisibility: false,
        child: SingleChildScrollView(
          controller: c,
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}

class WeightChangeCard extends StatelessWidget {
  const WeightChangeCard({
    super.key,
    required this.rows,
  });

  final List<({
  String memberId,
  String memberName,
  double? start,
  double? end,
  double? diff,
  })> rows;

  String _kg(double? v) {
    if (v == null) return '-';
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return '$s kg';
  }

  String _diffText(double d) {
    if (d > 0) return '+${d.toStringAsFixed(1)} kg';
    if (d < 0) return '${d.toStringAsFixed(1)} kg';
    return '0.0 kg';
  }

  IconData _diffIcon(double d) {
    if (d > 0) return Icons.trending_up_rounded;
    if (d < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = Theme.of(context).hintColor;
    final border = Theme.of(context).dividerColor;

    final done = rows.where((r) => r.diff != null).toList();
    final pending = rows.where((r) => r.diff == null).toList();

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(text: '${done.length}/${rows.length} lengkap', icon: Icons.verified_rounded),
              const Spacer(),
              Text(
                'Awal → Akhir',
                style: TextStyle(fontSize: Tw.s2, color: hint, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: border),
          const SizedBox(height: 12),

          if (rows.isEmpty)
            Text('Tiada ahli.', style: TextStyle(color: hint))
          else ...[
            // ✅ show completed first
            ...done.map((r) {
              final d = r.diff!;
              final icon = _diffIcon(d);

              final pillBg = d == 0
                  ? cs.primary.withOpacity(0.06)
                  : (d > 0 ? cs.error.withOpacity(0.08) : cs.primary.withOpacity(0.08));

              final pillColor = d == 0
                  ? cs.primary
                  : (d > 0 ? cs.error : cs.primary);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Awal ${_kg(r.start)}  •  Akhir ${_kg(r.end)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: hint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: border),
                        color: pillBg,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: pillColor),
                          const SizedBox(width: 6),
                          Text(
                            _diffText(d),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: pillColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (pending.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: border),
              const SizedBox(height: 8),
              Text(
                'Belum lengkap (perlukan Awal & Akhir)',
                style: TextStyle(fontWeight: FontWeight.w900, color: hint, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...pending.map((r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Awal ${_kg(r.start)} • Akhir ${_kg(r.end)}',
                        style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class WeightDailyCard extends StatelessWidget {
  const WeightDailyCard({
    super.key,
    required this.rows,
    required this.membersCount,
    required this.membersWithAny,
    required this.entriesTotal,
    required this.lastUpdated,
  });

  final List<({
  String memberId,
  String memberName,
  int entries,
  String? firstDate,
  String? lastDate,
  double? firstWeight,
  double? lastWeight,
  double? diff,
  })> rows;

  final int membersCount;
  final int membersWithAny;
  final int entriesTotal;
  final String? lastUpdated;

  String _kg(double? v) {
    if (v == null) return '-';
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return '$s kg';
  }

  String _diffText(double d) {
    if (d > 0) return '+${d.toStringAsFixed(1)} kg';
    if (d < 0) return '${d.toStringAsFixed(1)} kg';
    return '0.0 kg';
  }

  IconData _diffIcon(double d) {
    if (d > 0) return Icons.trending_up_rounded;
    if (d < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = Theme.of(context).hintColor;
    final border = Theme.of(context).dividerColor;

    final withAny = rows.where((r) => r.entries > 0).toList();
    final none = rows.where((r) => r.entries == 0).toList();

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(
                text: 'Harian: $membersWithAny/$membersCount ahli',
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(width: 10),
              Pill(
                text: '$entriesTotal entri',
                icon: Icons.list_alt_rounded,
              ),
              const Spacer(),
              Text(
                lastUpdated == null ? '—' : 'Updated $lastUpdated',
                style: TextStyle(fontSize: Tw.s2, color: hint, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: border),
          const SizedBox(height: 12),

          if (rows.isEmpty)
            Text('Tiada ahli.', style: TextStyle(color: hint))
          else ...[
            // ✅ members with daily entries
            ...withAny.map((r) {
              final d = r.diff ?? 0.0;
              final icon = _diffIcon(d);

              final pillBg = d == 0
                  ? cs.primary.withOpacity(0.06)
                  : (d > 0 ? cs.error.withOpacity(0.08) : cs.primary.withOpacity(0.08));

              final pillColor = d == 0 ? cs.primary : (d > 0 ? cs.error : cs.primary);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${r.entries} entri • ${r.firstDate} → ${r.lastDate}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Awal ${_kg(r.firstWeight)} • Akhir ${_kg(r.lastWeight)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: border),
                        color: pillBg,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: pillColor),
                          const SizedBox(width: 6),
                          Text(
                            _diffText(d),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: pillColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ✅ members without daily entries
            if (none.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: border),
              const SizedBox(height: 8),
              Text(
                'Belum ada rekod harian',
                style: TextStyle(fontWeight: FontWeight.w900, color: hint, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...none.map((r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('0 entri', style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

// -----------------------------
// ✅ UI: Not fasting combined
// -----------------------------
class NotFastingCombinedCard extends StatelessWidget {
  final List<({String id, String name})> members;
  final List<({String id, String name, int streak})> streakRows;

  final List<({
  String memberId,
  String memberName,
  int day,
  String? reason,
  bool fidyahPaid,
  })> notFastingEntries;

  const NotFastingCombinedCard({
    required this.members,
    required this.streakRows,
    required this.notFastingEntries,
  });

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;

    final byMember = <String, List<({
    String memberId,
    String memberName,
    int day,
    String? reason,
    bool fidyahPaid,
    })>>{};

    for (final e in notFastingEntries) {
      byMember.putIfAbsent(e.memberId, () => []).add(e);
    }
    for (final list in byMember.values) {
      list.sort((a, b) => b.day.compareTo(a.day));
    }

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BreezeStreaksCard(
            streakRows: streakRows,
            maxDays: 30,
            showTopPill: false,
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            'Sebab Tidak Puasa (rekod terkini)',
            style: TextStyle(fontWeight: FontWeight.w900, color: hint),
          ),
          const SizedBox(height: 10),
          if (notFastingEntries.isEmpty)
            Text('Tiada rekod “Tidak Puasa” lagi.', style: TextStyle(color: hint))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in members)
                  if ((byMember[m.id]?.isNotEmpty ?? false))
                    ReasonMiniCard(
                      memberName: m.name,
                      entries: byMember[m.id]!,
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class ReasonMiniCard extends StatelessWidget {
  final String memberName;

  final List<({
  String memberId,
  String memberName,
  int day,
  String? reason,
  bool fidyahPaid,
  })> entries;

  const ReasonMiniCard({
    required this.memberName,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = Theme.of(context).dividerColor;
    final hint = Theme.of(context).hintColor;

    final top3 = entries.take(3).toList();

    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        color: cs.primary.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              BreezePill(text: '${entries.length} hari', icon: Icons.calendar_today_rounded),
            ],
          ),
          const SizedBox(height: 10),
          ...top3.map((e) {
            final text = (e.reason == null || e.reason!.trim().isEmpty) ? '(Tiada sebab)' : e.reason!.trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: border),
                      color: cs.primary.withOpacity(0.06),
                    ),
                    child: Text(
                      'Hari ${e.day}',
                      style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (entries.length > 3)
            Text(
              '+ ${entries.length - 3} rekod lagi',
              style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

// -----------------------------
// ✅ UI: Fidyah payment card
// -----------------------------
class FidyahPaymentCard extends StatelessWidget {
  static const double _ratePerDay = 4.0; // 1 Hari = RM 4

  final List<({
  String memberId,
  String memberName,
  int day,
  String? reason,
  bool fidyahPaid,
  })> entries;

  final Future<void> Function(String memberId, String memberName, bool paid) onSetAllPaid;

  const FidyahPaymentCard({
    required this.entries,
    required this.onSetAllPaid,
  });

  String _rm(double v) {
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    return 'RM $s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = Theme.of(context).hintColor;

    final map = <String, List<({
    String memberId,
    String memberName,
    int day,
    String? reason,
    bool fidyahPaid,
    })>>{};

    for (final e in entries) {
      map.putIfAbsent(e.memberId, () => []).add(e);
    }

    final rows = map.entries.map((kv) {
      final memberId = kv.key;
      final list = kv.value;
      final memberName = list.first.memberName;
      final total = list.length;
      final paid = list.where((x) => x.fidyahPaid).length;
      final unpaid = total - paid;

      final totalAmount = total * _ratePerDay;
      final paidAmount = paid * _ratePerDay;
      final unpaidAmount = unpaid * _ratePerDay;

      return (
      memberId: memberId,
      memberName: memberName,
      total: total,
      paid: paid,
      unpaid: unpaid,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      unpaidAmount: unpaidAmount,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final totalAll = entries.length;
    final paidAll = entries.where((e) => e.fidyahPaid).length;
    final unpaidAll = totalAll - paidAll;

    final totalAmountAll = totalAll * _ratePerDay;
    final paidAmountAll = paidAll * _ratePerDay;
    final unpaidAmountAll = unpaidAll * _ratePerDay;

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.payments_rounded, color: cs.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Fidyah', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              BreezePill(text: '$paidAll / $totalAll dibayar', icon: Icons.verified_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              BreezePill(text: '1 Hari = ${_rm(_ratePerDay)}', icon: Icons.info_outline_rounded),
              BreezePill(text: 'Jumlah: ${_rm(totalAmountAll)}', icon: Icons.calculate_rounded),
              BreezePill(text: 'Dibayar: ${_rm(paidAmountAll)}', icon: Icons.check_circle_rounded),
              BreezePill(text: 'Baki: ${_rm(unpaidAmountAll)}', icon: Icons.pending_actions_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text('Tiada rekod fidyah.', style: TextStyle(color: hint))
          else
            ...rows.map((r) {
              final allPaid = r.paid == r.total && r.total > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jumlah: ${_rm(r.totalAmount)} • Dibayar: ${_rm(r.paidAmount)} • Baki: ${_rm(r.unpaidAmount)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: hint, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    BreezePill(text: '${r.paid}/${r.total}', icon: Icons.receipt_long_rounded),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () async => onSetAllPaid(r.memberId, r.memberName, !allPaid),
                        icon: Icon(
                          allPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: allPaid ? cs.primary : hint,
                        ),
                        label: Text(allPaid ? 'Semua Dibayar' : 'Tanda Semua'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                            color: allPaid ? cs.primary : Theme.of(context).dividerColor,
                            width: allPaid ? 2 : 1,
                          ),
                          backgroundColor: allPaid ? cs.primary.withOpacity(0.08) : Colors.transparent,
                          textStyle: TextStyle(fontWeight: allPaid ? FontWeight.w900 : FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class HomeReminderCard extends ConsumerStatefulWidget {
  const HomeReminderCard({
    super.key,
    required this.messages,
    this.onTap,
    this.secondsPerMessage = 10,
    this.typeSpeedMs = 22,
  });

  final List<String> messages;
  final VoidCallback? onTap;

  final int secondsPerMessage; // rotate interval
  final int typeSpeedMs; // typing speed

  @override
  ConsumerState<HomeReminderCard> createState() => _HomeReminderCardState();
}

class _HomeReminderCardState extends ConsumerState<HomeReminderCard> with SingleTickerProviderStateMixin {
  int _msgIndex = 0;
  int _charCount = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  Timer? _rotateTimer;
  Timer? _typeTimer;

  String get _currentMessage => widget.messages.isEmpty
      ? ''
      : widget.messages[_msgIndex % widget.messages.length];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _startCycle();
  }

  @override
  void didUpdateWidget(covariant HomeReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages) {
      _msgIndex = 0;
      _restartTyping();
    }
  }

  void _startCycle() {
    _fadeCtrl.forward();
    _restartTyping();

    _rotateTimer?.cancel();
    _rotateTimer = Timer.periodic(
      Duration(seconds: widget.secondsPerMessage),
          (_) => _nextMessage(),
    );
  }

  void _restartTyping() {
    _typeTimer?.cancel();
    setState(() => _charCount = 0);

    final msg = _currentMessage;
    if (msg.isEmpty) return;

    _typeTimer = Timer.periodic(
      Duration(milliseconds: widget.typeSpeedMs),
          (t) {
        if (!mounted) return;
        if (_charCount >= msg.length) {
          t.cancel();
        } else {
          setState(() => _charCount++);
        }
      },
    );
  }

  void _nextMessage() async {
    if (!mounted || widget.messages.isEmpty) return;

    // fade out
    await _fadeCtrl.reverse();

    if (!mounted) return;

    setState(() {
      _msgIndex = (_msgIndex + 1) % widget.messages.length;
      _charCount = 0;
    });

    // fade in + retype
    await _fadeCtrl.forward();
    _restartTyping();
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _typeTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = Theme.of(context).dividerColor;
    final hint = Theme.of(context).hintColor;

    final msg = _currentMessage;
    final typed = (msg.isEmpty)
        ? ''
        : msg.substring(0, _charCount.clamp(0, msg.length));

    return BreezeCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.primary.withOpacity(0.10),
              border: Border.all(color: border),
            ),
            child: Icon(Icons.notifications_active_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ STATIC header (never changes)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pengumuman:',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: border),
                        color: cs.primary.withOpacity(0.06),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew_rounded, size: 14, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            'auto',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ✅ ONLY message animates + typewriter
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Text(
                      typed,
                      style: TextStyle(
                        color: hint,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),

                // ✅ ONLY THIS PART is clickable
                if (widget.onTap != null) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Tekan untuk buka tracker',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Tutup (hari ini)',
            onPressed: () {
              final today = isoTodayKey(DateTime.now());
              ref.read(homeReminderProvider.notifier).dismissToday(today);
            },
            icon: Icon(Icons.close_rounded, color: hint),
          ),
        ],
      ),
    );
  }
}