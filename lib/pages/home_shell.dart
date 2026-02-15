import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadhan_hero/models/plan_type.dart';
import 'package:url_launcher/url_launcher.dart';

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

            ({String memberName, int juz, DateTime at})? latestJuzHousehold() {
              ({String memberName, int juz, DateTime at})? best;

              for (final mem in members) {
                final m = membersData[mem.id] as Map<String, dynamic>?;
                final jm = (m?['juz'] as Map<String, dynamic>?) ?? {};

                for (final entry in jm.entries) {
                  final key = entry.key; // "1".."30"
                  final v = entry.value;

                  bool done = false;
                  Timestamp? ts;

                  if (v == true) {
                    // old data: no timestamp => cannot be "recent"
                    continue;
                  } else if (v is Map) {
                    done = v['done'] == true;
                    final rawTs = v['lastAt'];
                    if (rawTs is Timestamp) ts = rawTs;
                  }

                  if (!done || ts == null) continue;

                  final at = ts.toDate();
                  final juzNo = int.tryParse(key) ?? 0;
                  if (juzNo < 1 || juzNo > 30) continue;

                  if (best == null || at.isAfter(best.at)) {
                    best = (memberName: mem.name, juz: juzNo, at: at);
                  }
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
                : 'Terbaru: Surah ${latestSurah.name} • ${formatTime12h(latestSurah.at)} oleh ${latestSurah.memberName}';

            final latestJuz = latestJuzHousehold();
            final latestJuzText = latestJuz == null
                ? 'Belum ada rekod terkini'
                : 'Terbaru: Juzuk ${latestJuz.juz} • ${formatTime12h(latestJuz.at)} oleh ${latestJuz.memberName}';

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
            // ✅ WEIGHT: Wajib checkpoints (Awal/Akhir) + Daily summary
            // ---------------------------
            final nMembers = members.length;

            // -------- Wajib (checkpoints)
            int startDone = 0;
            int endDone = 0;

            final weightRows = <({
            String memberId,
            String memberName,
            double? start,
            double? end,
            double? diff,
            })>[];

            for (final mem in members) {
              final cp = weightCheckpointMap(mem.id);
              final s = cp['start'];
              final e = cp['end'];
              final sv = (s is num) ? s.toDouble() : null;
              final ev = (e is num) ? e.toDouble() : null;

              if (sv != null) startDone++;
              if (ev != null) endDone++;

              final diff = (sv != null && ev != null) ? (ev - sv) : null;

              weightRows.add((
              memberId: mem.id,
              memberName: mem.name,
              start: sv,
              end: ev,
              diff: diff,
              ));
            }

            // Sort: complete first, bigger abs diff first
            weightRows.sort((a, b) {
              final ad = a.diff;
              final bd = b.diff;
              if (ad == null && bd == null) return a.memberName.compareTo(b.memberName);
              if (ad == null) return 1;
              if (bd == null) return -1;
              final byAbs = bd.abs().compareTo(ad.abs());
              if (byAbs != 0) return byAbs;
              return a.memberName.compareTo(b.memberName);
            });

            int wajibDoneBoth = 0;
            double wajibTotalDiff = 0.0;
            int gainCount = 0;
            int loseCount = 0;
            int sameCount = 0;

            for (final r in weightRows) {
              if (r.diff == null) continue;
              wajibDoneBoth++;
              wajibTotalDiff += r.diff!;
              if (r.diff! > 0) gainCount++;
              else if (r.diff! < 0) loseCount++;
              else sameCount++;
            }

            double? avgDiff = wajibDoneBoth == 0 ? null : wajibTotalDiff / wajibDoneBoth;

            // -------- Daily (per member)
            final dailyRows = <({
            String memberId,
            String memberName,
            int entries,
            String? firstDate,
            String? lastDate,
            double? firstWeight,
            double? lastWeight,
            double? diff,
            })>[];

            int dailyMembersWithAny = 0;
            int dailyEntriesTotal = 0;
            String? lastWeightUpdated; // global YYYY-MM-DD

            for (final mem in members) {
              final wm = weightMap(mem.id); // {YYYY-MM-DD: weight}

              final entries = <({String date, double w})>[];
              for (final kv in wm.entries) {
                final d = kv.key;
                final raw = kv.value;
                if (raw is num) entries.add((date: d, w: raw.toDouble()));
              }

              if (entries.isNotEmpty) {
                dailyMembersWithAny++;
                dailyEntriesTotal += entries.length;

                entries.sort((a, b) => a.date.compareTo(b.date)); // asc
                final first = entries.first;
                final last = entries.last;

                // global last updated
                if (lastWeightUpdated == null || last.date.compareTo(lastWeightUpdated!) > 0) {
                  lastWeightUpdated = last.date;
                }

                dailyRows.add((
                memberId: mem.id,
                memberName: mem.name,
                entries: entries.length,
                firstDate: first.date,
                lastDate: last.date,
                firstWeight: first.w,
                lastWeight: last.w,
                diff: last.w - first.w,
                ));
              } else {
                dailyRows.add((
                memberId: mem.id,
                memberName: mem.name,
                entries: 0,
                firstDate: null,
                lastDate: null,
                firstWeight: null,
                lastWeight: null,
                diff: null,
                ));
              }
            }

            // Sort daily: entries desc, then lastDate desc
            dailyRows.sort((a, b) {
              final byEntries = b.entries.compareTo(a.entries);
              if (byEntries != 0) return byEntries;
              final ad = a.lastDate ?? '';
              final bd = b.lastDate ?? '';
              return bd.compareTo(ad);
            });

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
                title: Text('Ramadan Hero • ${profile.planType.title}'),
                actions: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                      color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                    ),
                    child: const ThemeToggle(),
                  ),

                  SizedBox(width: 10),

                  // 👇 This one goes to Settings page
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                      color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        context.go("/settings");
                      },
                    ),
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
                    padding: EdgeInsetsGeometry.only(left: Tw.s8, right: Tw.s8, bottom: Tw.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Powered by ',
                              style: TextStyle(
                                fontSize: Tw.s2,
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse('https://fnxsolution.com'); // change URL
                                final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                if (!ok) debugPrint('Could not launch $uri');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/fnx.png',
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Assalamualaikum, Hero 👋',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Tw.gap(Tw.s2),
                        Text(
                          'Pilih tracker untuk kemaskini progres Ramadan',
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
                                  footer: latestJuzText,
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
                                  subtitle: lastWeightUpdated == null
                                      ? 'Belum ada rekod harian'
                                      : 'Last updated: $lastWeightUpdated',
                                  icon: Icons.monitor_weight_outlined,
                                  onTap: () => context.go('/tracker-weight'),
                                  badgeText: 'Berat Rekod',
                                  footer: 'Harian: $dailyMembersWithAny ahli • $dailyEntriesTotal entri',
                                  trendText: null,
                                  trendIcon: null,
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
                          title: 'Berat',
                          subtitle: 'Pantau berat sepanjang bulan Ramadan.',
                          icon: Icons.insights_rounded,
                          trailing: (avgDiff == null)
                              ? null
                              : Pill(
                            text: avgDiff > 0
                                ? 'Avg +${avgDiff.toStringAsFixed(1)} kg'
                                : avgDiff < 0
                                ? 'Avg ${avgDiff.toStringAsFixed(1)} kg'
                                : 'Avg 0.0 kg',
                            icon: avgDiff > 0
                                ? Icons.trending_up_rounded
                                : avgDiff < 0
                                ? Icons.trending_down_rounded
                                : Icons.trending_flat_rounded,
                          ),
                        ),

                        Tw.gap(Tw.s3),

                        // ✅ Wajib card
                        WeightChangeCard(rows: weightRows),

                        Tw.gap(Tw.s4),

                        // ✅ Daily card
                        WeightDailyCard(
                          rows: dailyRows,
                          membersCount: nMembers,
                          membersWithAny: dailyMembersWithAny,
                          entriesTotal: dailyEntriesTotal,
                          lastUpdated: lastWeightUpdated,
                        ),

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