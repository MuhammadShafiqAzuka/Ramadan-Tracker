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

        // Members list (same logic you use in pages)
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

            Map<String, dynamic> juzMap(String memberId) =>
                (node(memberId)?['juz'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> surahDatesMap(String memberId) =>
                (node(memberId)?['surahDates'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> weightMap(String memberId) =>
                (node(memberId)?['weight'] as Map<String, dynamic>?) ?? {};

            // ---------------------------
            // Progress: FASTING (household)
            // ---------------------------
            int fastingDoneCells = 0;
            for (final mem in members) {
              final fm = fastingMap(mem.id);
              for (var d = 1; d <= 30; d++) {
                if (fm['$d'] == true) fastingDoneCells++;
              }
            }
            final fastingTotalCells = members.length * 30;
            final fastingPct = safeDiv(fastingDoneCells, fastingTotalCells);

            // ---------------------------
            // Progress: JUZ (household)
            // ---------------------------
            int juzDoneCells = 0;
            for (final mem in members) {
              final jm = juzMap(mem.id);
              for (var j = 1; j <= 30; j++) {
                if (jm['$j'] == true) juzDoneCells++;
              }
            }
            final juzTotalCells = members.length * 30;
            final juzPct = safeDiv(juzDoneCells, juzTotalCells);

            // ---------------------------
            // Progress: SURAH today count (household)
            // ---------------------------
            int surahTodayCount = 0;
            for (final mem in members) {
              final sm = surahDatesMap(mem.id);
              for (var s = 1; s <= 114; s++) {
                final dates = (sm['$s'] as List?)?.cast<String>() ?? const <String>[];
                if (dates.contains(today)) surahTodayCount++;
              }
            }

            // ---------------------------
            // Progress: WEIGHT trend (household)
            // ---------------------------
            double? earliestWeight;
            String? earliestDate;
            double? latestWeight;
            String? latestDate;

            for (final mem in members) {
              final wm = weightMap(mem.id);
              for (final entry in wm.entries) {
                final date = entry.key; // YYYY-MM-DD
                final w = (entry.value as num).toDouble();

                if (earliestDate == null || date.compareTo(earliestDate) < 0) {
                  earliestDate = date;
                  earliestWeight = w;
                }
                if (latestDate == null || date.compareTo(latestDate) > 0) {
                  latestDate = date;
                  latestWeight = w;
                }
              }
            }

            final weightTrend = (earliestWeight != null && latestWeight != null)
                ? (latestWeight - earliestWeight)
                : null;

            // ---------------------------
            // Streaks: fasting streak per member (day index based)
            // ---------------------------
            int memberStreak(String memberId) {
              final fm = fastingMap(memberId);
              int last = 0;
              for (var d = 1; d <= 30; d++) {
                if (fm['$d'] == true) last = d;
              }
              int streak = 0;
              for (var d = last; d >= 1; d--) {
                if (fm['$d'] == true) {
                  streak++;
                } else {
                  break;
                }
              }
              return streak;
            }

            final streakRows = [
              for (final mem in members)
                (id: mem.id, name: mem.name, streak: memberStreak(mem.id)),
            ]..sort((a, b) => b.streak.compareTo(a.streak));

            final topStreak = streakRows.isNotEmpty ? streakRows.first.streak : 0;

            // ---------------------------
            // Day-based summary: fasting completed per day
            // ---------------------------
            List<int> fastingPerDayDone = List.filled(30, 0);
            for (var day = 1; day <= 30; day++) {
              int done = 0;
              for (final mem in members) {
                if (fastingMap(mem.id)['$day'] == true) done++;
              }
              fastingPerDayDone[day - 1] = done;
            }

            // ---------------------------
            // Leaderboard: combined score (fasting + juz + unique surah)
            // ---------------------------
            int fastingCount(String memberId) {
              final fm = fastingMap(memberId);
              int done = 0;
              for (var d = 1; d <= 30; d++) {
                if (fm['$d'] == true) done++;
              }
              return done;
            }

            int juzCount(String memberId) {
              final jm = juzMap(memberId);
              int done = 0;
              for (var j = 1; j <= 30; j++) {
                if (jm['$j'] == true) done++;
              }
              return done;
            }

            int uniqueSurahCount(String memberId) {
              final sm = surahDatesMap(memberId);
              int unique = 0;
              for (var s = 1; s <= 114; s++) {
                final dates = (sm['$s'] as List?)?.cast<String>() ?? const <String>[];
                if (dates.isNotEmpty) unique++;
              }
              return unique;
            }

            final leaderboard = [
              for (final mem in members)
                (
                id: mem.id,
                name: mem.name,
                fasting: fastingCount(mem.id),
                juz: juzCount(mem.id),
                surah: uniqueSurahCount(mem.id),
                )
            ]
              ..sort((a, b) {
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

                        // Breeze-ish "dashboard cards" (clean, rounded, subtle)
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
                                  subtitle: '${(fastingPct * 100).round()}%  •  $fastingDoneCells / $fastingTotalCells',
                                  icon: Icons.check_circle_outline,
                                  onTap: () => context.go('/tracker-fasting'),
                                  footer: 'Top streak: $topStreak day(s)',
                                  badgeText: 'Hari 1– Hari 30',
                                  progress: fastingPct,
                                  valueText: '${(fastingPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Juzuk',
                                  subtitle: '${(juzPct * 100).round()}%  •  $juzDoneCells / $juzTotalCells',
                                  icon: Icons.menu_book_outlined,
                                  onTap: () => context.go('/tracker-juz'),
                                  footer: 'Target: 30 juzuk',
                                  badgeText: '1–30',
                                  progress: juzPct,
                                  valueText: '${(juzPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Surah (Hari ini)',
                                  subtitle: '$surahTodayCount bacaan hari ini',
                                  icon: Icons.library_books_outlined,
                                  onTap: () => context.go('/tracker-surah'),
                                  footer: 'Date: $today',
                                  badgeText: 'Daily',
                                ),
                                BreezeProgressCard(
                                  title: 'Berat',
                                  subtitle: weightTrend == null
                                      ? 'Tiada data lagi'
                                      : '${weightTrend >= 0 ? '+' : ''}${weightTrend.toStringAsFixed(1)} kg',
                                  icon: Icons.monitor_weight_outlined,
                                  onTap: () => context.go('/tracker-weight'),
                                  footer: (earliestDate != null && latestDate != null)
                                      ? 'Dari $earliestDate → $latestDate'
                                      : 'Isi berat',
                                  badgeText: 'Trend',
                                ),
                              ],
                            );
                          },
                        ),

                        Tw.gap(Tw.s10),

                        // ---- Modern Streaks (Breeze list + progress bars)
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

                        // ---- Modern Ramadan day summary (horizontal chips)
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

                        // ---- Modern Leaderboard (podium + tiles)
                        SectionHeader(
                          title: 'Leaderboard Keluarga ${profile.parents.first}',
                          subtitle: 'Markah = Puasa + Juzuk + Surah',
                          icon: Icons.emoji_events_rounded,
                          trailing: Pill(
                            text: 'Score: P + J + S',
                            icon: Icons.info_outline_rounded,
                          ),
                        ),
                        Tw.gap(Tw.s3),
                        BreezeLeaderboardCard(leaderboard: leaderboard),

                        Tw.gap(Tw.s4),
                        Text(
                          'Markah = Puasa (0–30) + Juz (0–30) + Surah yang dibaca (0–114)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Tw.darkSubtext
                                : Tw.slate700,
                          ),
                        ),
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