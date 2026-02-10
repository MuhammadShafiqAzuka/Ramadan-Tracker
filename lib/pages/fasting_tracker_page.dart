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

            // ✅ fasting score/multiplier per day: 0.0, 0.5, 1.0 (backward compatible with bool)
            double fastingValue(String memberId, int day) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              final raw = fm?['$day'];

              if (raw == null) return 0.0;
              if (raw is bool) return raw ? 1.0 : 0.0; // old data
              if (raw is int) return raw.toDouble();
              if (raw is double) return raw;
              if (raw is num) return raw.toDouble();
              return 0.0;
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

            // ✅ NEW SCORE MODEL:
            // day score = solatDone(0..5) + puasaBonus(0/0.5/1)
            // max per day = 6
            double dayScore(String memberId, int day) {
              final solat = solatDoneCount(memberId, day).toDouble(); // 0..5
              final puasa = fastingValue(memberId, day); // 0,0.5,1
              return solat + puasa; // 0..6
            }

            double memberScore(String memberId) {
              double total = 0;
              for (var d = 1; d <= 30; d++) {
                total += dayScore(memberId, d);
              }
              return total; // 0..180
            }

            // ✅ Household overall progress (score-based)
            final totalScoreMax = members.length * _maxPerMonth; // members*180

            double householdScore = 0;
            for (final mem in members) {
              householdScore += memberScore(mem.id);
            }

            final overall = totalScoreMax == 0 ? 0.0 : (householdScore / totalScoreMax);

            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            final selectedScore = (selected == null) ? 0.0 : memberScore(selected);
            final selectedProgress = (selected == null) ? 0.0 : (selectedScore / _maxPerMonth);

            // keep selectedDay valid
            if (selectedDay < 1) selectedDay = 1;
            if (selectedDay > 30) selectedDay = 30;

            // current day (selectedDay) values
            final todayFastingVal = (selected == null) ? 0.0 : fastingValue(selected, selectedDay);
            final solatCount = (selected == null) ? 0 : solatDoneCount(selected, selectedDay);
            final solatPct = solatCount / 5.0;

            // today total (solat + puasa)
            final todayTotal = (selected == null) ? 0.0 : dayScore(selected, selectedDay);
            final todayTotalPct = todayTotal / _maxPerDay;

            // label helper
            String puasaLabel(double v) {
              if (v >= 1.0) return 'Puasa Penuh';
              if (v >= 0.5) return 'Puasa Yang Yuk';
              return 'Tidak Puasa';
            }

            return BreezeWebScaffold(
              title: 'Penjejak Puasa ($_year)',
              onLogout: () async => ref.read(authServiceProvider).logout(),
              body: SingleChildScrollView(
                padding: Tw.p(Tw.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BreezeSectionHeader(
                      title: 'Keseluruhan',
                      subtitle: 'Score isi rumah (Solat + Puasa) untuk Ramadhan Hari 1 - Hari 30',
                      icon: Icons.dashboard_rounded,
                      trailing: BreezePill(
                        text:
                        '${(overall * 100).round()}%  •  ${householdScore.toStringAsFixed(1)} / ${totalScoreMax.toStringAsFixed(0)}',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    Tw.gap(Tw.s3),
                    BreezeProgressBlock(
                      title: 'Progress Isi Rumah (Markah)',
                      value: overall,
                      rightText: '${(overall * 100).round()}%',
                      subtitle:
                      '${householdScore.toStringAsFixed(1)} markah dari ${totalScoreMax.toStringAsFixed(0)} max',
                    ),

                    Tw.gap(Tw.s5),

                    BreezeSectionHeader(
                      title: 'Ahli',
                      subtitle: 'Pilih ahli yang anda mahu kemas kini',
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
                        subtitle: '${selectedScore.toStringAsFixed(1)} / ${_maxPerMonth.toStringAsFixed(0)} score',
                      ),
                      Tw.gap(Tw.s5),

                      // ✅ PUASA GRID: tap selects day ONLY (no toggle fasting here)
                      BreezeSectionHeader(
                        title: 'Puasa',
                        subtitle: 'Klik Hari untuk pilih hari (Solat ikut hari ini).',
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
                              childAspectRatio: 2.2,
                            ),
                            itemBuilder: (context, idx) {
                              final day = idx + 1;

                              final val = fastingValue(selected, day); // 0,0.5,1
                              final checked = val > 0.0;
                              final isSelected = day == selectedDay;

                              final label = val == 0.5 ? 'Hari $day (½)' : 'Hari $day';
                              final icon = val == 0.5
                                  ? Icons.brightness_5_rounded
                                  : Icons.nights_stay_rounded;

                              final chip = BreezeToggleChip(
                                label: label,
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

                      // ✅ SOLAT SECTION: follows selectedDay
                      BreezeSectionHeader(
                        title: 'Solat (Hari $selectedDay)',
                        subtitle: 'Tanda 5 waktu untuk hari yang dipilih',
                        icon: Icons.mosque_rounded,
                        trailing: BreezePill(
                          text: '$solatCount / 5',
                          icon: Icons.fact_check_rounded,
                        ),
                      ),
                      Tw.gap(Tw.s3),

                      // ✅ Overall day score (Solat + Puasa) => max 6
                      BreezeProgressBlock(
                        title: 'Score Hari $selectedDay (Solat + Puasa)',
                        value: todayTotalPct,
                        rightText: '${(todayTotalPct * 100).round()}%',
                        subtitle: '${todayTotal.toStringAsFixed(1)} / ${_maxPerDay.toStringAsFixed(0)} • ${puasaLabel(todayFastingVal)}',
                      ),

                      Tw.gap(Tw.s4),

                      // ✅ Buttons: set puasa bonus for selectedDay (0/0.5/1)
                      BreezeCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () async {
                                  final mem = members.firstWhere((m) => m.id == selected);
                                  await fasting.setFastingScore(
                                    uid: profile.uid,
                                    year: _year,
                                    memberId: mem.id,
                                    memberName: mem.name,
                                    day: selectedDay,
                                    score: 0.5,
                                  );
                                },
                                child: const Text('Puasa Yang Yuk'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  final mem = members.firstWhere((m) => m.id == selected);
                                  await fasting.setFastingScore(
                                    uid: profile.uid,
                                    year: _year,
                                    memberId: mem.id,
                                    memberName: mem.name,
                                    day: selectedDay,
                                    score: 1.0,
                                  );
                                },
                                child: const Text('Puasa Penuh'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              tooltip: 'Kosongkan puasa hari ini',
                              onPressed: () async {
                                final mem = members.firstWhere((m) => m.id == selected);
                                await fasting.setFastingScore(
                                  uid: profile.uid,
                                  year: _year,
                                  memberId: mem.id,
                                  memberName: mem.name,
                                  day: selectedDay,
                                  score: 0.0,
                                );
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
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

                      Tw.gap(Tw.s3),
                      Text(
                        'Status Hari $selectedDay: ${puasaLabel(todayFastingVal)} • Solat $solatCount/5 • Score ${todayTotal.toStringAsFixed(1)}/6',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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