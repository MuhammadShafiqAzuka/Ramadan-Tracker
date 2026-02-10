import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ramadhan_hero/models/plan_type.dart';

import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../utils/date_key.dart';
import '../utils/mathx.dart';
import '../utils/tw.dart';
import '../widgets/breeze_ui.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _prayers = <String>['subuh', 'zohor', 'asar', 'maghrib', 'isyak'];

  static const double _puasaMaxPerDay = 6.0;     // 5 solat + 1 puasa
  static const double _puasaMaxPerMember = 180.0; // 30 * 6

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(child: Text('Failed to load profile: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile missing. Please login again.')));
        }

        final name = profile.parents.isNotEmpty ? profile.parents.first : profile.email;
        final year = DateTime.now().year;

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

        final yearAsync = ref.watch(ramadhanYearProvider((uid: profile.uid, year: year)));

        return yearAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(
              title: Text('Ramadan Hero • ${profile.planType.title}'),
              actions: [
                TextButton(
                  onPressed: () async => ref.read(authServiceProvider).logout(),
                  child: const Text('Log keluar'),
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(
              title: Text('Ramadan Hero • ${profile.planType.title}'),
              actions: [
                TextButton(
                  onPressed: () async => ref.read(authServiceProvider).logout(),
                  child: const Text('Log keluar'),
                ),
              ],
            ),
            body: Center(child: Text('Failed to load year data: $e')),
          ),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};
            final today = isoDayKey(DateTime.now());

            Map<String, dynamic>? node(String memberId) =>
                membersData[memberId] as Map<String, dynamic>?;

            Map<String, dynamic> fastingMap(String memberId) =>
                (node(memberId)?['fasting'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> solatMap(String memberId) =>
                (node(memberId)?['solat'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> juzMap(String memberId) =>
                (node(memberId)?['juz'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> surahDatesMap(String memberId) =>
                (node(memberId)?['surahDates'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> weightMap(String memberId) =>
                (node(memberId)?['weight'] as Map<String, dynamic>?) ?? {};

            // ---------------------------
            // ✅ PUASA SCORE (per member max 180)
            // day score = solatDone(0..5) + puasaBonus(0/0.5/1)
            // max per day = 6, max per member = 30*6 = 180
            // ---------------------------
            double fastingValue(String memberId, int day) {
              final fm = fastingMap(memberId);
              final raw = fm['$day'];
              if (raw == null) return 0.0;
              if (raw is bool) return raw ? 1.0 : 0.0; // old data
              if (raw is int) return raw.toDouble();
              if (raw is double) return raw;
              if (raw is num) return raw.toDouble();
              return 0.0;
            }

            int solatDoneCount(String memberId, int day) {
              final sm = solatMap(memberId);
              final dayMap =
                  (sm['$day'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
              int c = 0;
              for (final k in _prayers) {
                if (dayMap[k] == true) c++;
              }
              return c; // 0..5
            }

            double memberPuasaScore(String memberId) {
              double total = 0;
              for (var d = 1; d <= 30; d++) {
                final solat = solatDoneCount(memberId, d).toDouble(); // 0..5
                final puasa = fastingValue(memberId, d);              // 0,0.5,1
                total += (solat + puasa);                             // 0..6
              }
              return total; // 0..180
            }

            // ---------------------------
            // ✅ JUZ SCORE (per member max 30)
            // ---------------------------
            int memberJuzScore(String memberId) {
              final jm = juzMap(memberId);
              int done = 0;
              for (var j = 1; j <= 30; j++) {
                if (jm['$j'] == true) done++;
              }
              return done; // 0..30
            }

            // ---------------------------
            // ✅ SURAH SCORE (per member max 114)
            // unique surah read at least once
            // ---------------------------
            int memberSurahScore(String memberId) {
              final sm = surahDatesMap(memberId);
              int unique = 0;
              for (var s = 1; s <= 114; s++) {
                final dates = (sm['$s'] as List?)?.cast<String>() ?? const <String>[];
                if (dates.isNotEmpty) unique++;
              }
              return unique; // 0..114
            }

            // Household dashboard stats
            double puasaScoreHousehold = 0;
            int juzDoneHousehold = 0;
            int surahUniqueHousehold = 0;

            for (final mem in members) {
              puasaScoreHousehold += memberPuasaScore(mem.id);
              juzDoneHousehold += memberJuzScore(mem.id);
              surahUniqueHousehold += memberSurahScore(mem.id);
            }

            final puasaMaxHousehold = members.length * _puasaMaxPerMember; // members*180
            final puasaPct =
            puasaMaxHousehold == 0 ? 0.0 : (puasaScoreHousehold / puasaMaxHousehold);

            final juzMaxHousehold = members.length * 30;
            final juzPct = safeDiv(juzDoneHousehold, juzMaxHousehold);

            final surahMaxHousehold = members.length * 114;
            final surahPct = safeDiv(surahUniqueHousehold, surahMaxHousehold);

            // ---------------------------
            // Streaks: fasting streak per member (treat fastingValue>0)
            // ---------------------------
            bool isFasted(String memberId, int day) => fastingValue(memberId, day) > 0.0;

            int memberStreak(String memberId) {
              int last = 0;
              for (var d = 1; d <= 30; d++) {
                if (isFasted(memberId, d)) last = d;
              }
              int streak = 0;
              for (var d = last; d >= 1; d--) {
                if (isFasted(memberId, d)) {
                  streak++;
                } else {
                  break;
                }
              }
              return streak;
            }

            final streakRows = [
              for (final mem in members) (id: mem.id, name: mem.name, streak: memberStreak(mem.id)),
            ]..sort((a, b) => b.streak.compareTo(a.streak));

            final topStreak = streakRows.isNotEmpty ? streakRows.first.streak : 0;

            // Day-based summary: fasting completed per day (count >0)
            List<int> fastingPerDayDone = List.filled(30, 0);
            for (var day = 1; day <= 30; day++) {
              int done = 0;
              for (final mem in members) {
                if (isFasted(mem.id, day)) done++;
              }
              fastingPerDayDone[day - 1] = done;
            }

            // --- Weight dashboard trend (household): latest vs previous entry overall ---
            double? latestW;
            String? latestD;
            double? prevW;
            String? prevD;

            for (final mem in members) {
              final wm = weightMap(mem.id);
              final entries = wm.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
              if (entries.isEmpty) continue;

              final d0 = entries[0].key;
              final w0 = (entries[0].value as num).toDouble();

              if (latestD == null || d0.compareTo(latestD) > 0) {
                if (latestD != null) {
                  prevD = latestD;
                  prevW = latestW;
                }
                latestD = d0;
                latestW = w0;

                if (entries.length >= 2) {
                  prevD ??= entries[1].key;
                  prevW ??= (entries[1].value as num).toDouble();
                }
              } else {
                if (prevD == null || d0.compareTo(prevD) > 0) {
                  if (latestD == null || d0 != latestD) {
                    prevD = d0;
                    prevW = w0;
                  }
                }
              }
            }

            final weightDiff = (latestW != null && prevW != null) ? (latestW - prevW) : null;

            IconData? weightTrendIcon;
            String? weightTrendText;

            if (weightDiff != null) {
              if (weightDiff > 0) {
                weightTrendIcon = Icons.trending_up_rounded;
                weightTrendText = '+${weightDiff.toStringAsFixed(1)} kg';
              } else if (weightDiff < 0) {
                weightTrendIcon = Icons.trending_down_rounded;
                weightTrendText = '${weightDiff.toStringAsFixed(1)} kg';
              } else {
                weightTrendIcon = Icons.trending_flat_rounded;
                weightTrendText = '0.0 kg';
              }
            }

            // ---------------------------
            // ✅ LEADERBOARD: PuasaScore(0..180) + Juz(0..30) + Surah(0..114)
            // total max = 324 per member
            // ---------------------------
            final leaderboard = [
              for (final mem in members)
                (
                id: mem.id,
                name: mem.name,
                fasting: memberPuasaScore(mem.id).round(), // 0..180 (int for UI)
                juz: memberJuzScore(mem.id),               // 0..30
                surah: memberSurahScore(mem.id),           // 0..114
                )
            ]..sort((a, b) {
              final scoreA = a.fasting + a.juz + a.surah;
              final scoreB = b.fasting + b.juz + b.surah;
              return scoreB.compareTo(scoreA);
            });

            return Scaffold(
              appBar: AppBar(
                title: Text('Ramadan Hero • ${profile.planType.title}'),
                actions: [
                  TextButton(
                    onPressed: () async => ref.read(authServiceProvider).logout(),
                    child: const Text('Log keluar'),
                  ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: Tw.p(Tw.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Assalamualaikum, $name 👋',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Tw.gap(Tw.s2),
                        Text(
                          'Pilih tracker untuk kemaskini progres Ramadan.',
                          style: Tw.subtitle.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Tw.darkSubtext
                                : Tw.slate700,
                          ),
                        ),
                        Tw.gap(Tw.s6),

                        LayoutBuilder(
                          builder: (context, c) {
                            final wide = c.maxWidth >= 760;
                            return GridView.count(
                              crossAxisCount: wide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: wide ? 2.35 : 2.75,
                              children: [
                                BreezeProgressCard(
                                  title: 'Puasa',
                                  subtitle:
                                  '${(puasaPct * 100).round()}% • ${puasaScoreHousehold.toStringAsFixed(1)} / ${puasaMaxHousehold.toStringAsFixed(0)}',
                                  icon: Icons.check_circle_outline,
                                  onTap: () => context.go('/tracker-fasting'),
                                  footer: 'Top streak: $topStreak hari',
                                  badgeText: 'Markah (Solat + Puasa)',
                                  progress: puasaPct,
                                  valueText: '${(puasaPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Juzuk',
                                  subtitle:
                                  '${(juzPct * 100).round()}% • $juzDoneHousehold / $juzMaxHousehold',
                                  icon: Icons.menu_book_outlined,
                                  onTap: () => context.go('/tracker-juz'),
                                  footer: 'Target: 30 juzuk setiap ahli',
                                  badgeText: '30 Juzuk setiap ahli',
                                  progress: juzPct,
                                  valueText: '${(juzPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Surah',
                                  subtitle:
                                  '${(surahPct * 100).round()}% • $surahUniqueHousehold / $surahMaxHousehold',
                                  icon: Icons.library_books_outlined,
                                  onTap: () => context.go('/tracker-surah'),
                                  footer: 'Hari ini: $today',
                                  badgeText: '114 Surah setiap ahli',
                                  progress: surahPct,
                                  valueText: '${(surahPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Berat',
                                  subtitle: weightTrendText == null
                                      ? 'Tiada lagi trend'
                                      : '$weightTrendText (terkini)',
                                  icon: Icons.monitor_weight_outlined,
                                  onTap: () => context.go('/tracker-weight'),
                                  footer: (latestD != null && prevD != null)
                                      ? 'Kemaskini: $latestD (sebelum: $prevD)'
                                      : (latestD != null ? 'Kemaskini: $latestD' : 'Isi berat'),
                                  badgeText: 'Trend',
                                  trendText: weightTrendText,
                                  trendIcon: weightTrendIcon,
                                ),
                              ],
                            );
                          },
                        ),

                        Tw.gap(Tw.s10),

                        SectionHeader(
                          title: 'Streaks (Berpuasa)',
                          subtitle: 'Tanda berturut-turut berakhir pada hari yang diperiksa terkini',
                          icon: Icons.local_fire_department_rounded,
                        ),
                        Tw.gap(Tw.s3),
                        BreezeStreaksCard(
                          streakRows: streakRows,
                          maxDays: 30,
                        ),

                        Tw.gap(Tw.s10),

                        SectionHeader(
                          title: 'Ramadan Day Summary (Berpuasa)',
                          subtitle: 'Status isi rumah setiap hari',
                          icon: Icons.calendar_month_rounded,
                        ),
                        Tw.gap(Tw.s3),
                        BreezeCard(
                          child: WheelToHorizontalScroll(
                            child: Row(
                              children: [
                                for (var day = 1; day <= 30; day++) ...[
                                  MiniDayChip(
                                    label: 'Hari $day',
                                    subtitle: '${fastingPerDayDone[day - 1]}/${members.length}',
                                  ),
                                  if (day != 30) const SizedBox(width: 10),
                                ],
                              ],
                            ),
                          ),
                        ),

                        Tw.gap(Tw.s10),

                        SectionHeader(
                          title: 'Leaderboard Keluarga ${profile.parents.first}',
                          subtitle: 'Markah = Puasa & Solat (0–180) + Juzuk (0–30) + Surah (0–114)',
                          icon: Icons.emoji_events_rounded,
                        ),
                        Tw.gap(Tw.s3),
                        BreezeLeaderboardCard(leaderboard: leaderboard),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}