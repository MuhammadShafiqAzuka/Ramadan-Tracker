import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/tw.dart';

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
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(rightText, style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onLogout != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonal(
                onPressed: onLogout,
                child: const Text('Keluar'),
              ),
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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }
}

class BreezeProgressCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String footer;
  final String badgeText;
  final IconData icon;
  final VoidCallback onTap;

  /// Optional (0..1). If null, no bar.
  final double? progress;

  /// Optional right pill value (e.g. "62%")
  final String? valueText;

  const BreezeProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.badgeText,
    required this.icon,
    required this.onTap,
    this.progress,
    this.valueText,
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

    final border = isDark ? Tw.darkBorder : Tw.slate200;
    final sub = isDark ? Tw.darkSubtext : Tw.slate700;

    Widget pill(String text, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
          color: cs.primary.withOpacity(isDark ? 0.10 : 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    final bg = isDark ? Tw.darkCard : Tw.white;

    // subtle hover lift for web, keep dark minimal
    final shadow = (!isDark && _hover) ? Tw.shadowMd : const <BoxShadow>[];

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
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: cs.primary.withOpacity(isDark ? 0.14 : 0.10),
                          border: Border.all(color: border),
                        ),
                        child: Icon(widget.icon, color: cs.primary),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),

                      const SizedBox(width: 10),
                      pill(widget.badgeText),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Subtitle (2-line clamp -> neat grid)
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: sub,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (widget.progress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: widget.progress!.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: (isDark ? Tw.darkBorder : Tw.slate200).withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Footer row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.footer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: sub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      if (widget.valueText != null) ...[
                        const SizedBox(width: 10),
                        pill(widget.valueText!, icon: Icons.trending_up_rounded),
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

  const BreezeStreaksCard({required this.streakRows, required this.maxDays});

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
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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
                        style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).hintColor),
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
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (isTop) ...[
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
                                      fontSize: 12,
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
                        style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary),
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

class BreezeLeaderboardCard extends StatelessWidget {
  final List<({String id, String name, int fasting, int juz, int surah})> leaderboard;

  const BreezeLeaderboardCard({required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    final top3 = leaderboard.take(3).toList();
    final rest = leaderboard.length > 3 ? leaderboard.sublist(3) : const [];

    return BreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (top3.isNotEmpty) ...[
            BreezePodium(top3: top3),
            const SizedBox(height: 14),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 10),
          ],
          if (leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No data yet — start ticking trackers 😊',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            )
          else
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

    Widget box({required int rank, required ({String id, String name, int fasting, int juz, int surah}) row}) {
      final ratio = switch (rank) {
        1 => 2.30, // tallest
        2 => 2.60,
        _ => 2.75, // shortest
      };

      return AspectRatio(
        aspectRatio: ratio,
        child: BreezePodiumCard(rank: rank, row: row),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 560;

        if (stacked) {
          return Column(
            children: [
              if (first != null) box(rank: 1, row: first),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: second != null ? box(rank: 2, row: second) : const SizedBox()),
                  const SizedBox(width: 10),
                  Expanded(child: third != null ? box(rank: 3, row: third) : const SizedBox()),
                ],
              ),
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
    final score = row.fasting + row.juz + row.surah;

    final icon = switch (rank) {
      1 => Icons.emoji_events_rounded,
      2 => Icons.workspace_premium_rounded,
      _ => Icons.military_tech_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(rank == 1 ? 0.14 : 0.09),
            Theme.of(context).cardColor,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary),
              const Spacer(),
              Pill(text: '#$rank'),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ This area gets squeezed sometimes; make it unbreakable:
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ClipRect( // ✅ prevents RenderFlex overflow in extreme constraints
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Markah $score • P ${row.fasting} • J ${row.juz} • S ${row.surah}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11, // ✅ slightly smaller so it fits more often
                        color: Theme.of(context).hintColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  const BreezeLeaderboardTile({
    required this.rank,
    required this.name,
    required this.fasting,
    required this.juz,
    required this.surah,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$rank',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          BreezeTinyStat(label: 'P', value: fasting),
          BreezeTinyStat(label: 'J', value: juz),
          BreezeTinyStat(label: 'S', value: surah),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Theme.of(context).dividerColor),
              color: cs.primary.withOpacity(0.08),
            ),
            child: Text(
              '$score',
              style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary),
            ),
          ),
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
