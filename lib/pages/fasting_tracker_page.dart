import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadhan_hero/models/plan_type.dart';

import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/fasting_service.dart';
import '../utils/tw.dart';
import '../widgets/breeze_ui.dart';

class FastingTrackerPage extends ConsumerStatefulWidget {
  const FastingTrackerPage({super.key, this.year});
  final int? year;

  @override
  ConsumerState<FastingTrackerPage> createState() => _FastingTrackerPageState();
}

class _FastingTrackerPageState extends ConsumerState<FastingTrackerPage> {
  String? selectedMemberId;

  /// ✅ Tap Puasa grid selects day; Solat follows this
  int selectedDay = 1;

  int get _year => widget.year ?? DateTime.now().year;

  // ✅ new max score model: per day max = 5 solat + 1 puasa = 6
  static const double _maxPerDay = 6.0;
  static const double _maxPerMonth = 30.0 * _maxPerDay; // 180

  static const _prayers = <({String key, String label, IconData icon})>[
    (key: 'subuh', label: 'Subuh', icon: Icons.wb_twilight_rounded),
    (key: 'zohor', label: 'Zohor', icon: Icons.wb_sunny_outlined),
    (key: 'asar', label: 'Asar', icon: Icons.wb_sunny_rounded),
    (key: 'maghrib', label: 'Maghrib', icon: Icons.nightlight_round),
    (key: 'isyak', label: 'Isyak', icon: Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile missing.')));
        }

        // Members list
        final members = <({String id, String name})>[];
        if (profile.planType.id == 'solo') {
          final fallbackName = profile.parents.isNotEmpty ? profile.parents.first : 'Self';
          members.add((id: 'self', name: fallbackName));
        } else {
          for (var i = 0; i < profile.parents.length; i++) {
            members.add((id: 'parent_$i', name: profile.parents[i]));
          }
          for (var i = 0; i < profile.children.length; i++) {
            members.add((id: 'child_$i', name: profile.children[i]));
          }
        }

        final selected = selectedMemberId ?? (members.isNotEmpty ? members.first.id : null);

        final fasting = ref.read(fastingServiceProvider);
        final yearAsync = ref.watch(ramadhanYearProvider((uid: profile.uid, year: _year)));

        return yearAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Failed to load: $e'))),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic>? memberNode(String memberId) =>
                membersData[memberId] as Map<String, dynamic>?;

            /// ✅ fasting score per day:
            /// - persisted: 0.0, 0.5, 1.0 (backward compatible with bool)
            /// - DEFAULT (when missing): 0.0  ✅ (user must click to record)
            double fastingValue(String memberId, int day) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              final raw = fm?['$day'];

              if (raw == null) return 0.0; // ✅ DEFAULT is 0.0 (not recorded / belum update)
              if (raw is bool) return raw ? 1.0 : 0.0; // old data
              if (raw is int) return raw.toDouble();
              if (raw is double) return raw;
              if (raw is num) return raw.toDouble();
              return 0.0;
            }

            /// ✅ whether fasting day is explicitly recorded in Firestore
            bool isFastingRecorded(String memberId, int day) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              return fm != null && fm.containsKey('$day');
            }

            /// ✅ Count explicitly saved "Tidak Puasa" days (score == 0.0 AND recorded)
            int notFastingDays(String memberId) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              if (fm == null) return 0;

              int c = 0;
              for (var d = 1; d <= 30; d++) {
                final raw = fm['$d'];
                if (raw == null) continue;

                final v = (raw is bool)
                    ? (raw ? 1.0 : 0.0)
                    : (raw is num ? raw.toDouble() : null);

                if ((v ?? 0.0) == 0.0) c++;
              }
              return c;
            }

            /// ✅ Count recorded fasting days (any recorded value: 0 / 0.5 / 1)
            int recordedFastingDays(String memberId) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              if (fm == null) return 0;

              int c = 0;
              for (var d = 1; d <= 30; d++) {
                if (fm.containsKey('$d')) c++;
              }
              return c;
            }

            // ✅ solat helpers (per member, per day)
            Map<String, dynamic> solatDayMap(String memberId, int day) {
              final m = memberNode(memberId);
              final solat = m?['solat'] as Map<String, dynamic>?;
              final dayMap = solat?['$day'] as Map<String, dynamic>?;
              return dayMap ?? {};
            }

            bool isSolatDone(String memberId, int day, String prayerKey) {
              final dm = solatDayMap(memberId, day);
              return dm[prayerKey] == true;
            }

            int solatDoneCount(String memberId, int day) {
              var c = 0;
              for (final p in _prayers) {
                if (isSolatDone(memberId, day, p.key)) c++;
              }
              return c; // 0..5
            }

            // ✅ score model:
            // day score = solatDone(0..5) + puasa(0/0.5/1)
            // max per day = 6
            double dayScore(String memberId, int day) {
              final solat = solatDoneCount(memberId, day).toDouble(); // 0..5
              final puasa = fastingValue(memberId, day); // 0,0.5,1 (default 0)
              return solat + puasa; // 0..6
            }

            double memberScore(String memberId) {
              double total = 0;
              for (var d = 1; d <= 30; d++) {
                total += dayScore(memberId, d);
              }
              return total; // 0..180
            }

            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            final selectedScore = (selected == null) ? 0.0 : memberScore(selected);
            final selectedProgress = (selected == null) ? 0.0 : (selectedScore / _maxPerMonth);

            // keep selectedDay valid
            if (selectedDay < 1) selectedDay = 1;
            if (selectedDay > 30) selectedDay = 30;

            // current day values
            final todayFastingVal = (selected == null) ? 0.0 : fastingValue(selected, selectedDay);
            final todayFastingRecorded =
            (selected == null) ? false : isFastingRecorded(selected, selectedDay);

            final solatCount = (selected == null) ? 0 : solatDoneCount(selected, selectedDay);

            final todayTotal = (selected == null) ? 0.0 : dayScore(selected, selectedDay);
            final todayTotalPct = todayTotal / _maxPerDay;

            String puasaLabel(double v, {required bool recorded}) {
              if (!recorded) return 'Belum Rekod';
              if (v >= 1.0) return 'Puasa Penuh';
              if (v >= 0.5) return 'Puasa Separuh';
              return 'Tidak Puasa';
            }

            String missingSolatLabel(String memberId, int day) {
              final missing = <String>[];
              for (final p in _prayers) {
                if (!isSolatDone(memberId, day, p.key)) missing.add(p.label);
              }
              if (missing.isEmpty) return 'Lengkap';
              return 'Belum: ${missing.join(", ")}';
            }

            final selectedNotFastingCount = (selected == null) ? 0 : notFastingDays(selected);
            final selectedRecordedFastingCount = (selected == null) ? 0 : recordedFastingDays(selected);

            return BreezeWebScaffold(
              title: 'Penjejak Puasa ($_year)',
              onLogout: () async => ref.read(authServiceProvider).logout(),
              body: SingleChildScrollView(
                padding: Tw.p(Tw.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BreezeSectionHeader(
                      title: 'Ahli',
                      subtitle: 'Pilih ahli keluarga yang anda mahu kemas kini',
                      icon: Icons.people_alt_rounded,
                    ),
                    Tw.gap(Tw.s3),
                    BreezeMemberSelector(
                      members: members,
                      value: selected,
                      onChanged: (v) => setState(() {
                        selectedMemberId = v;
                        selectedDay = 1;
                      }),
                    ),

                    Tw.gap(Tw.s5),

                    if (selected != null) ...[
                      BreezeProgressBlock(
                        title: 'Progress untuk $selectedName (Markah)',
                        value: selectedProgress,
                        rightText: '${(selectedProgress * 100).round()}%',
                        subtitle:
                        '${selectedScore.toStringAsFixed(1)} / ${_maxPerMonth.toStringAsFixed(0)} score'
                            '  •  Rekod Puasa: $selectedRecordedFastingCount/30'
                            '  •  Tidak Puasa: $selectedNotFastingCount hari',
                      ),
                      Tw.gap(Tw.s5),

                      BreezeSectionHeader(
                        title: 'Puasa',
                        subtitle: 'Default = 0 (Belum Rekod). Tekan butang untuk rekod status puasa.',
                        icon: Icons.calendar_month_rounded,
                        trailing: BreezePill(text: 'Hari $selectedDay', icon: Icons.today_rounded),
                      ),
                      Tw.gap(Tw.s3),

                      LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final cross = w >= 860
                              ? 10
                              : w >= 700
                              ? 8
                              : w >= 520
                              ? 6
                              : 4;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 30,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cross,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.8,
                            ),
                            itemBuilder: (context, idx) {
                              final day = idx + 1;

                              final val = fastingValue(selected, day); // default 0
                              final recorded = isFastingRecorded(selected, day);
                              final isSelected = day == selectedDay;

                              final icon = !recorded
                                  ? Icons.help_outline_rounded
                                  : (val >= 1.0
                                  ? Icons.nights_stay_rounded
                                  : (val >= 0.5
                                  ? Icons.brightness_5_rounded
                                  : Icons.cancel_rounded));

                              // visual cue: checked when recorded
                              final checked = recorded;

                              final chip = BreezeToggleChip(
                                label: 'Hari $day',
                                checked: checked,
                                icon: icon,
                                onTap: () => setState(() => selectedDay = day),
                              );

                              return isSelected
                                  ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: chip,
                                ),
                              )
                                  : chip;
                            },
                          );
                        },
                      ),

                      Tw.gap(Tw.s6),

                      BreezeSectionHeader(
                        title: 'Solat (Hari $selectedDay)',
                        subtitle: 'Markah = Solat (0-5) untuk 1 hari',
                        icon: Icons.mosque_rounded,
                        trailing: BreezePill(
                          text: '$solatCount / 5',
                          icon: Icons.fact_check_rounded,
                        ),
                      ),
                      Tw.gap(Tw.s3),

                      BreezeProgressBlock(
                        title: 'Score Hari $selectedDay (Puasa + Solat)',
                        value: todayTotalPct,
                        rightText: '${(todayTotalPct * 100).round()}%',
                        subtitle:
                        '${todayTotal.toStringAsFixed(1)} / ${_maxPerDay.toStringAsFixed(0)}',
                      ),

                      Tw.gap(Tw.s4),

                      // ✅ Buttons: set puasa score for selectedDay (0 / 0.5 / 1)
                      BreezeCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ✅ Status header (neat, clear)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    Icon(Icons.event_available_rounded,
                                        size: 18, color: Theme.of(context).colorScheme.primary),
                                    Text(
                                      'Hari $selectedDay',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                                        ),
                                      ),
                                      child: Text(
                                        puasaLabel(todayFastingVal, recorded: todayFastingRecorded),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.10),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.20),
                                        ),
                                      ),
                                      child: Text(
                                        'Solat: $solatCount/5',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ✅ Missing solat line (only when needed)
                              if (selected != null)
                                Text(
                                  missingSolatLabel(selected, selectedDay),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // ✅ Action buttons (responsive + consistent sizing)
                              LayoutBuilder(
                                builder: (context, c) {
                                  final isNarrow = c.maxWidth < 560;

                                  final mem = members.firstWhere((m) => m.id == selected);

                                  final currentScore = todayFastingVal; // 0.0, 0.5, 1.0

                                  Widget fastingButton({
                                    required String label,
                                    required double value,
                                  }) {
                                    final isSelected = currentScore == value && todayFastingRecorded;

                                    return SizedBox(
                                      height: 44,
                                      width: isNarrow ? double.infinity : 180,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await fasting.setFastingScore(
                                            uid: profile.uid,
                                            year: _year,
                                            memberId: mem.id,
                                            memberName: mem.name,
                                            day: selectedDay,
                                            score: value,
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).dividerColor,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          backgroundColor: isSelected
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                              : Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          textStyle: TextStyle(
                                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                          ),
                                        ),
                                        child: Text(label),
                                      ),
                                    );
                                  }

                                  final buttons = <Widget>[
                                    fastingButton(label: 'Tidak Puasa', value: 0.0),
                                    fastingButton(label: 'Puasa Separuh', value: 0.5),
                                    fastingButton(label: 'Puasa Penuh', value: 1.0),
                                  ];

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        ...buttons.expand((w) sync* {
                                          yield w;
                                          yield const SizedBox(height: 10);
                                        }).toList()
                                          ..removeLast(),
                                      ],
                                    );
                                  }

                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: buttons,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      Tw.gap(Tw.s4),

                      // ✅ Solat toggles
                      LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final cross = w >= 860
                              ? 5
                              : w >= 700
                              ? 5
                              : w >= 520
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _prayers.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cross,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.4,
                            ),
                            itemBuilder: (context, i) {
                              final p = _prayers[i];
                              final checked = isSolatDone(selected, selectedDay, p.key);

                              return BreezeToggleChip(
                                label: p.label,
                                checked: checked,
                                icon: p.icon,
                                onTap: () async {
                                  final mem = members.firstWhere((m) => m.id == selected);
                                  final current = isSolatDone(selected, selectedDay, p.key);

                                  await fasting.setSolat(
                                    uid: profile.uid,
                                    year: _year,
                                    memberId: mem.id,
                                    memberName: mem.name,
                                    day: selectedDay,
                                    prayerKey: p.key,
                                    value: !current,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}