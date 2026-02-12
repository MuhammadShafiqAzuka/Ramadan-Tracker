import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadhan_hero/models/plan_type.dart';

import '../providers/fasting_provider.dart';
import '../providers/home_reminder.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/fasting_service.dart';
import '../utils/date_key.dart';
import '../utils/mathx.dart';
import '../utils/tw.dart';
import '../widgets/breeze_ui.dart';
import '../widgets/theme_toggle.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _prayers = <String>['subuh', 'zohor', 'asar', 'maghrib', 'isyak'];
  static const double _puasaMaxPerMember = 180.0; // 30 * 6

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Tw.darkBorder : Tw.slate200;

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
        final isSolo = profile.planType.id == 'solo';

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
        final fastingSvc = ref.read(fastingServiceProvider);

        return yearAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Scaffold(
            body: Center(child: Text('Failed to load year data: $e')),
          ),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic>? node(String memberId) =>
                membersData[memberId] as Map<String, dynamic>?;

            Map<String, dynamic> fastingMap(String memberId) =>
                (node(memberId)?['fasting'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> fastingReasonMap(String memberId) =>
                (node(memberId)?['fastingReason'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> fidyahPaidMap(String memberId) =>
                (node(memberId)?['fidyahPaid'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> solatMap(String memberId) =>
                (node(memberId)?['solat'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> juzMap(String memberId) =>
                (node(memberId)?['juz'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> surahMap(String memberId) =>
                (node(memberId)?['surah'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> weightMap(String memberId) =>
                (node(memberId)?['weight'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> weightCheckpointMap(String memberId) =>
                (node(memberId)?['weightCheckpoint'] as Map<String, dynamic>?) ?? {};

            // ---------------------------
            // ✅ PUASA SCORE (per member max 180)
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

            String? fastingReason(String memberId, int day) {
              final rm = fastingReasonMap(memberId);
              final raw = rm['$day'];
              if (raw == null) return null;
              final s = raw.toString().trim();
              return s.isEmpty ? null : s;
            }

            bool isFidyahPaid(String memberId, int day) {
              final fm = fidyahPaidMap(memberId);
              return fm['$day'] == true;
            }

            int solatDoneCount(String memberId, int day) {
              final sm = solatMap(memberId);
              final dayMap = (sm['$day'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
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
                final puasa = fastingValue(memberId, d); // 0,0.5,1
                total += (solat + puasa); // 0..6
              }
              return total; // 0..180
            }

            // ---------------------------
            // ✅ JUZ SCORE
            // ---------------------------
            int memberJuzScore(String memberId) {
              final jm = juzMap(memberId);
              int done = 0;
              for (var j = 1; j <= 30; j++) {
                if (jm['$j'] == true) done++;
              }
              return done; // 0..30
            }

            ({int no, String name, DateTime at})? latestSurahRecitedByTime(String memberId) {
              final sm = surahMap(memberId);

              DateTime? bestAt;
              int? bestNo;
              String? bestName;

              for (final entry in sm.entries) {
                final surahKey = entry.key;
                final surahNode = (entry.value as Map?)?.cast<String, dynamic>();
                if (surahNode == null) continue;

                final ts = surahNode['lastRecitedAt'];
                if (ts is! Timestamp) continue;

                final at = ts.toDate();
                final no = (surahNode['no'] as num?)?.toInt() ?? int.tryParse(surahKey) ?? 0;
                final name = (surahNode['name'] as String?) ?? 'Surah $surahKey';

                if (bestAt == null || at.isAfter(bestAt)) {
                  bestAt = at;
                  bestNo = no;
                  bestName = name;
                }
              }

              if (bestAt == null || bestNo == null || bestName == null) return null;
              return (no: bestNo, name: bestName, at: bestAt);
            }

            ({String memberName, int no, String name, DateTime at})? latestSurahHousehold() {
              ({String memberName, int no, String name, DateTime at})? best;

              for (final mem in members) {
                final l = latestSurahRecitedByTime(mem.id);
                if (l == null) continue;

                if (best == null || l.at.isAfter(best.at)) {
                  best = (memberName: mem.name, no: l.no, name: l.name, at: l.at);
                }
              }
              return best;
            }

            int memberSurahScore(String memberId) {
              final sm = surahMap(memberId);
              int unique = 0;
              for (final entry in sm.entries) {
                final surahNode = (entry.value as Map?)?.cast<String, dynamic>();
                final dates = (surahNode?['dateRecited'] as List?)?.cast<String>() ?? const <String>[];
                if (dates.isNotEmpty) unique++;
              }
              return unique;
            }

            final latestSurah = latestSurahHousehold();
            final latestSurahText = latestSurah == null
                ? 'Belum ada rekod'
                : 'Terbaru: Surah ${latestSurah.name} • ${formatTime12h(latestSurah.at)} daripada ${latestSurah.memberName}';

            // Household dashboard stats
            double puasaScoreHousehold = 0;
            int juzDoneHousehold = 0;
            int surahUniqueHousehold = 0;

            for (final mem in members) {
              puasaScoreHousehold += memberPuasaScore(mem.id);
              juzDoneHousehold += memberJuzScore(mem.id);
              surahUniqueHousehold += memberSurahScore(mem.id);
            }

            final puasaMaxHousehold = members.length * _puasaMaxPerMember;
            final puasaPct = puasaMaxHousehold == 0 ? 0.0 : (puasaScoreHousehold / puasaMaxHousehold);

            final juzMaxHousehold = members.length * 30;
            final juzPct = safeDiv(juzDoneHousehold, juzMaxHousehold);

            final surahMaxHousehold = members.length * 114;
            final surahPct = safeDiv(surahUniqueHousehold, surahMaxHousehold);

            // ---------------------------
            // Streaks
            // ---------------------------
            bool isFasted(String memberId, int day) => fastingValue(memberId, day) > 0.0;

            bool isNotFasted(String memberId, int day) {
              final fm = fastingMap(memberId);
              if (!fm.containsKey('$day')) return false;
              return fastingValue(memberId, day) == 0.0;
            }

            int memberStreak(String memberId) {
              int last = 0;
              for (var d = 1; d <= 30; d++) {
                if (isFasted(memberId, d)) last = d;
              }
              int streak = 0;
              for (var d = last; d >= 1; d--) {
                if (isFasted(memberId, d)) streak++;
                else break;
              }
              return streak;
            }

            int memberNotFastingStreak(String memberId) {
              int last = 0;
              for (var d = 1; d <= 30; d++) {
                if (isNotFasted(memberId, d)) last = d;
              }
              int streak = 0;
              for (var d = last; d >= 1; d--) {
                if (isNotFasted(memberId, d)) streak++;
                else break;
              }
              return streak;
            }

            final streakRows = [
              for (final mem in members) (id: mem.id, name: mem.name, streak: memberStreak(mem.id)),
            ]..sort((a, b) => b.streak.compareTo(a.streak));

            final topStreak = streakRows.isNotEmpty ? streakRows.first.streak : 0;

            final notFastingStreakRows = [
              for (final mem in members) (id: mem.id, name: mem.name, streak: memberNotFastingStreak(mem.id)),
            ]..sort((a, b) => b.streak.compareTo(a.streak));

            // ---------------------------
            // ✅ Not fasting entries
            // ---------------------------
            final notFastingEntries = <({
            String memberId,
            String memberName,
            int day,
            String? reason,
            bool fidyahPaid,
            })>[];

            for (final mem in members) {
              for (var d = 1; d <= 30; d++) {
                if (!isNotFasted(mem.id, d)) continue;
                notFastingEntries.add((
                memberId: mem.id,
                memberName: mem.name,
                day: d,
                reason: fastingReason(mem.id, d),
                fidyahPaid: isFidyahPaid(mem.id, d),
                ));
              }
            }

            notFastingEntries.sort((a, b) {
              final byDay = b.day.compareTo(a.day);
              if (byDay != 0) return byDay;
              return a.memberName.compareTo(b.memberName);
            });

            // ---------------------------
            // ✅ WEIGHT: Mandatory checkpoints summary (start/end)
            // ---------------------------
            final nMembers = members.length;

            int startDone = 0;
            int endDone = 0;
            final diffs = <double>[];

            for (final mem in members) {
              final cp = weightCheckpointMap(mem.id);
              final s = cp['start'];
              final e = cp['end'];
              final sv = (s is num) ? s.toDouble() : null;
              final ev = (e is num) ? e.toDouble() : null;

              if (sv != null) startDone++;
              if (ev != null) endDone++;

              if (sv != null && ev != null) {
                diffs.add(ev - sv);
              }
            }

            double? avgCheckpointDiff;
            if (diffs.isNotEmpty) {
              avgCheckpointDiff = diffs.reduce((a, b) => a + b) / diffs.length;
            }

            String _fmtKg(double v) {
              final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
              return '$s kg';
            }

            String? checkpointDiffText;
            IconData? checkpointDiffIcon;
            if (avgCheckpointDiff != null) {
              if (avgCheckpointDiff > 0) {
                checkpointDiffIcon = Icons.trending_up_rounded;
                checkpointDiffText = '+${avgCheckpointDiff.toStringAsFixed(1)} kg';
              } else if (avgCheckpointDiff < 0) {
                checkpointDiffIcon = Icons.trending_down_rounded;
                checkpointDiffText = '${avgCheckpointDiff.toStringAsFixed(1)} kg';
              } else {
                checkpointDiffIcon = Icons.trending_flat_rounded;
                checkpointDiffText = '0.0 kg';
              }
            }

            // ---------------------------
            // ✅ WEIGHT: Daily trend based on LAST 2 daily entries globally
            // ---------------------------
            final allDaily = <({String date, double weight})>[];
            for (final mem in members) {
              final wm = weightMap(mem.id);
              for (final kv in wm.entries) {
                final date = kv.key; // YYYY-MM-DD
                final raw = kv.value;
                if (raw is num) {
                  allDaily.add((date: date, weight: raw.toDouble()));
                }
              }
            }
            allDaily.sort((a, b) => b.date.compareTo(a.date));

            double? latestW;
            String? latestD;
            double? prevW;
            String? prevD;

            if (allDaily.isNotEmpty) {
              latestD = allDaily[0].date;
              latestW = allDaily[0].weight;
            }
            if (allDaily.length >= 2) {
              prevD = allDaily[1].date;
              prevW = allDaily[1].weight;
            }

            final weightDiffDaily = (latestW != null && prevW != null) ? (latestW - prevW) : null;

            IconData? weightTrendIcon;
            String? weightTrendText;

            if (weightDiffDaily != null) {
              if (weightDiffDaily > 0) {
                weightTrendIcon = Icons.trending_up_rounded;
                weightTrendText = '+${weightDiffDaily.toStringAsFixed(1)} kg';
              } else if (weightDiffDaily < 0) {
                weightTrendIcon = Icons.trending_down_rounded;
                weightTrendText = '${weightDiffDaily.toStringAsFixed(1)} kg';
              } else {
                // ✅ avoid confusing "0.0 kg"
                weightTrendIcon = Icons.trending_flat_rounded;
                weightTrendText = 'Tiada perubahan';
              }
            }

            final weightFooter = (() {
              final parts = <String>[
                'Wajib: Awal $startDone/$nMembers • Akhir $endDone/$nMembers',
              ];

              if (checkpointDiffText != null) {
                parts.add('Avg perubahan: $checkpointDiffText');
              }

              if (latestD != null && prevD != null && weightTrendText != null) {
                parts.add('Trend harian: $weightTrendText ($latestD vs $prevD)');
              } else if (latestD != null) {
                parts.add('Entri harian terbaru: $latestD');
              } else {
                parts.add('Tiada rekod harian');
              }

              return parts.join(' • ');
            })();

            // ---------------------------
            // ✅ LEADERBOARD
            // ---------------------------
            final leaderboard = [
              for (final mem in members)
                (
                id: mem.id,
                name: mem.name,
                fasting: memberPuasaScore(mem.id).round(),
                juz: memberJuzScore(mem.id),
                surah: memberSurahScore(mem.id),
                )
            ]..sort((a, b) {
              final scoreA = a.fasting + a.juz + a.surah;
              final scoreB = b.fasting + b.juz + b.surah;
              return scoreB.compareTo(scoreA);
            });

            return Scaffold(
              appBar: AppBar(
                title: Text('Ramadan Hero • ${profile.planType.title} • Tahun $year'),
                actions: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                      color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                    ),
                    child: const ThemeToggle(),
                  ),
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
                          'Pilih tracker untuk kemaskini progres Ramadan $year',
                          style: Tw.subtitle.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? Tw.darkSubtext : Tw.slate700,
                          ),
                        ),
                        Tw.gap(Tw.s4),

                        // ✅ Warm in-app reminder (dismiss until tomorrow)
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final today = isoTodayKey(now);
                            final dismissed = ref.watch(homeReminderProvider);
                            final isDismissedToday = dismissed == today;

                            if (isDismissedToday) return const SizedBox.shrink();

                            return HomeReminderCard(
                              messages: reminders,
                              onTap: () => context.go('/tracker-fasting'),
                              secondsPerMessage: 10,
                              typeSpeedMs: 22,
                            );
                          },
                        ),

                        Tw.gap(Tw.s6),

                        LayoutBuilder(
                          builder: (context, c) {
                            final isPhone = MediaQuery.of(context).size.width < 480;
                            return GridView.count(
                              crossAxisCount: isPhone ? 1 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: isPhone ? 2 : 3.0,
                              children: [
                                BreezeProgressCard(
                                  title: 'Puasa',
                                  subtitle:
                                  '${(puasaPct * 100).round()}% • ${puasaScoreHousehold.toStringAsFixed(1)} / ${puasaMaxHousehold.toStringAsFixed(0)}',
                                  icon: Icons.check_circle_outline,
                                  onTap: () => context.go('/tracker-fasting'),
                                  footer: 'Top streak: $topStreak hari • Tidak puasa: ${notFastingEntries.length} rekod',
                                  badgeText: 'Markah (Solat + Puasa)',
                                  progress: puasaPct,
                                  valueText: '${(puasaPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Juzuk',
                                  subtitle: '${(juzPct * 100).round()}% • $juzDoneHousehold / $juzMaxHousehold',
                                  icon: Icons.menu_book_outlined,
                                  onTap: () => context.go('/tracker-juz'),
                                  footer: 'Target: 30 juzuk setiap ahli',
                                  badgeText: '30 Juzuk setiap ahli',
                                  progress: juzPct,
                                  valueText: '${(juzPct * 100).round()}%',
                                ),
                                BreezeProgressCard(
                                  title: 'Surah',
                                  subtitle: '${(surahPct * 100).round()}% • $surahUniqueHousehold / $surahMaxHousehold',
                                  icon: Icons.library_books_outlined,
                                  onTap: () => context.go('/tracker-surah'),
                                  footer: latestSurahText,
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
                                      ? 'Kemaskini: $latestD'
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
                          title: 'Streak Berpuasa',
                          subtitle: 'Rekod bilangan streak puasa untuk ahli keluarga',
                          icon: Icons.local_fire_department_rounded,
                        ),
                        Tw.gap(Tw.s3),
                        BreezeStreaksCard(streakRows: streakRows, maxDays: 30, showTopPill: true),

                        Tw.gap(Tw.s10),

                        SectionHeader(
                          title: 'Tidak Puasa',
                          subtitle: 'Rekod bilangan tidak puasa + sebab (kemas kini di tracker Puasa)',
                          icon: Icons.do_not_disturb_on_rounded,
                        ),
                        Tw.gap(Tw.s4),
                        NotFastingCombinedCard(
                          members: members,
                          streakRows: notFastingStreakRows,
                          notFastingEntries: notFastingEntries,
                        ),

                        if (notFastingEntries.isNotEmpty) ...[
                          Tw.gap(Tw.s10),
                          SectionHeader(
                            title: 'Fidyah',
                            subtitle: 'Tandakan bayaran fidyah (kira berdasarkan hari “Tidak Puasa”).',
                            icon: Icons.payments_rounded,
                          ),
                          Tw.gap(Tw.s3),
                          FidyahPaymentCard(
                            entries: notFastingEntries,
                            onSetAllPaid: (memberId, memberName, paid) async {
                              final days = notFastingEntries
                                  .where((e) => e.memberId == memberId)
                                  .map((e) => e.day)
                                  .toSet()
                                  .toList()
                                ..sort();

                              for (final day in days) {
                                await fastingSvc.setFidyahPaid(
                                  uid: profile.uid,
                                  year: year,
                                  memberId: memberId,
                                  memberName: memberName,
                                  day: day,
                                  paid: paid,
                                );
                              }
                            },
                          ),
                        ],

                        Tw.gap(Tw.s10),

                        SectionHeader(
                          title: isSolo ? 'Pencapaian' : 'Leaderboard Keluarga ${profile.parents.first}',
                          subtitle: isSolo
                              ? 'Markah anda: Puasa & Solat (0–180) + Juzuk (0–30) + Surah (0–114)'
                              : 'Markah = Puasa & Solat (0–180) + Juzuk (0–30) + Surah (0–114)',
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