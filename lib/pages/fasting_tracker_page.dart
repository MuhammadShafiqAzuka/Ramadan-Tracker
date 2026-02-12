import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_type.dart';
import '../models/user_profile.dart';
import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/fasting_service.dart';
import '../utils/tw.dart';
import '../widgets/breeze_ui.dart';
import '../widgets/not_fast_reason.dart';

class FastingTrackerPage extends ConsumerStatefulWidget {
  const FastingTrackerPage({super.key, this.year});
  final int? year;

  @override
  ConsumerState<FastingTrackerPage> createState() => _FastingTrackerPageState();
}

class _FastingTrackerPageState extends ConsumerState<FastingTrackerPage> {
  String? selectedMemberId;
  int selectedDay = 1;

  int get _year => widget.year ?? DateTime.now().year;

  // ✅ Achievement scoring (same as your first UI)
  // per day max = 5 solat + 1 puasa = 6
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

        final members = _buildMembers(profile);
        final selected = selectedMemberId ?? (members.isNotEmpty ? members.first.id : null);

        final fasting = ref.read(fastingServiceProvider);
        final yearAsync = ref.watch(ramadhanYearProvider((uid: profile.uid, year: _year)));

        return yearAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Failed to load: $e'))),
          data: (data) {
            // keep selectedDay valid
            if (selectedDay < 1) selectedDay = 1;
            if (selectedDay > 30) selectedDay = 30;

            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic>? memberNode(String memberId) =>
                membersData[memberId] as Map<String, dynamic>?;

            // -------------------------
            // READ HELPERS (Puasa)
            // -------------------------
            double fastingValue(String memberId, int day) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              final raw = fm?['$day'];

              if (raw == null) return 0.0; // default
              if (raw is bool) return raw ? 1.0 : 0.0; // old data
              if (raw is int) return raw.toDouble();
              if (raw is double) return raw;
              if (raw is num) return raw.toDouble();
              return 0.0;
            }

            bool isFastingRecorded(String memberId, int day) {
              final m = memberNode(memberId);
              final fm = m?['fasting'] as Map<String, dynamic>?;
              return fm != null && fm.containsKey('$day');
            }

            // ✅ reason for "Tidak Puasa"
            String? fastingReason(String memberId, int day) {
              final m = memberNode(memberId);
              final rm = m?['fastingReason'] as Map<String, dynamic>?;
              final raw = rm?['$day'];
              if (raw == null) return null;
              final s = raw.toString().trim();
              return s.isEmpty ? null : s;
            }

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

            // -------------------------
            // READ HELPERS (Solat)
            // -------------------------
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

            String missingSolatLabel(String memberId, int day) {
              final missing = <String>[];
              for (final p in _prayers) {
                if (!isSolatDone(memberId, day, p.key)) missing.add(p.label);
              }
              if (missing.isEmpty) return 'Lengkap';
              return 'Belum: ${missing.join(", ")}';
            }

            // -------------------------
            // READ HELPERS (Tarawih / Sedekah / Sahur)
            // -------------------------
            int? tarawihRakaat(String memberId, int day) {
              final m = memberNode(memberId);
              final tm = m?['tarawih'] as Map<String, dynamic>?;
              final raw = tm?['$day'];
              if (raw == null) return null;
              if (raw is int) return raw;
              if (raw is num) return raw.toInt();
              return null;
            }

            bool isTarawihRecorded(String memberId, int day) {
              final m = memberNode(memberId);
              final tm = m?['tarawih'] as Map<String, dynamic>?;
              return tm != null && tm.containsKey('$day');
            }

            bool? sedekahValue(String memberId, int day) {
              final m = memberNode(memberId);
              final sm = m?['sedekah'] as Map<String, dynamic>?;
              final raw = sm?['$day'];
              if (raw == null) return null;
              if (raw is bool) return raw;
              return null;
            }

            bool isSedekahRecorded(String memberId, int day) {
              final m = memberNode(memberId);
              final sm = m?['sedekah'] as Map<String, dynamic>?;
              return sm != null && sm.containsKey('$day');
            }

            bool? sahurValue(String memberId, int day) {
              final m = memberNode(memberId);
              final sm = m?['sahur'] as Map<String, dynamic>?;
              final raw = sm?['$day'];
              if (raw == null) return null;
              if (raw is bool) return raw;
              return null;
            }

            bool isSahurRecorded(String memberId, int day) {
              final m = memberNode(memberId);
              final sm = m?['sahur'] as Map<String, dynamic>?;
              return sm != null && sm.containsKey('$day');
            }

            // -------------------------
            // SCORING (Achievement 180)
            // -------------------------
            double dayScore(String memberId, int day) {
              final solat = solatDoneCount(memberId, day).toDouble(); // 0..5
              final puasa = fastingValue(memberId, day); // 0, 0.5, 1
              return solat + puasa; // 0..6
            }

            double memberScore(String memberId) {
              double total = 0;
              for (var d = 1; d <= 30; d++) {
                total += dayScore(memberId, d);
              }
              return total; // 0..180
            }

            // -------------------------
            // UI COMPUTED (Selected)
            // -------------------------
            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            final recordedPuasaCount = (selected == null) ? 0 : recordedFastingDays(selected);
            final notPuasaCount = (selected == null) ? 0 : notFastingDays(selected);

            final selectedScore = (selected == null) ? 0.0 : memberScore(selected);
            final selectedProgress = (selected == null) ? 0.0 : (selectedScore / _maxPerMonth);

            final todayPuasaVal = (selected == null) ? 0.0 : fastingValue(selected, selectedDay);
            final todayPuasaRecorded =
            (selected == null) ? false : isFastingRecorded(selected, selectedDay);

            final todayPuasaReason =
            (selected == null) ? null : fastingReason(selected, selectedDay);

            final todaySolatCount = (selected == null) ? 0 : solatDoneCount(selected, selectedDay);

            final todayTarawih = (selected == null) ? null : tarawihRakaat(selected, selectedDay);
            final todayTarawihRecorded =
            (selected == null) ? false : isTarawihRecorded(selected, selectedDay);

            final todaySedekah = (selected == null) ? null : sedekahValue(selected, selectedDay);
            final todaySedekahRecorded =
            (selected == null) ? false : isSedekahRecorded(selected, selectedDay);

            final todaySahur = (selected == null) ? null : sahurValue(selected, selectedDay);
            final todaySahurRecorded =
            (selected == null) ? false : isSahurRecorded(selected, selectedDay);

            String puasaLabel(double v, {required bool recorded}) {
              if (!recorded) return 'Belum Rekod';
              if (v >= 1.0) return 'Puasa Penuh';
              if (v >= 0.5) return 'Puasa Separuh';
              return 'Tidak Puasa';
            }

            String tarawihLabel({required int? rakaat, required bool recorded}) {
              if (!recorded) return 'Belum Rekod';
              if (rakaat == 8) return 'Tarawih 8';
              if (rakaat == 20) return 'Tarawih 20';
              return 'Tak Set';
            }

            String boolLabel({
              required bool? v,
              required bool recorded,
              required String trueText,
              required String falseText,
            }) {
              if (!recorded) return 'Belum Rekod';
              return (v == true) ? trueText : falseText;
            }

            Future<void> onSetPuasa(double value) async {
              if (selected == null) return;
              final mem = members.firstWhere((m) => m.id == selected);

              // Tidak Puasa -> ask reason
              if (value == 0.0) {
                final reason = await _showTidakPuasaReasonDialog(context);
                if (reason == null) return; // cancelled

                await fasting.setFastingNotFastingWithReason(
                  uid: profile.uid,
                  year: _year,
                  memberId: mem.id,
                  memberName: mem.name,
                  day: selectedDay,
                  reason: reason,
                );
                return;
              }

              // Puasa Separuh / Penuh
              await fasting.setFastingScore(
                uid: profile.uid,
                year: _year,
                memberId: mem.id,
                memberName: mem.name,
                day: selectedDay,
                score: value,
              );

              // clear reason if any
              await fasting.clearFastingReason(
                uid: profile.uid,
                year: _year,
                memberId: mem.id,
                day: selectedDay,
              );
            }

            return BreezeWebScaffold(
              title: 'Penjejak Ramadhan ($_year)',
              onLogout: () async => ref.read(authServiceProvider).logout(),
              body: SingleChildScrollView(
                padding: Tw.p(Tw.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // -------------------------
                    // AHLI
                    // -------------------------
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
                      // ✅ Achievement like your first UI (180 score)
                      BreezeProgressBlock(
                        title: 'Progress untuk $selectedName (Markah)',
                        value: selectedProgress,
                        rightText: '${(selectedProgress * 100).round()}%',
                        subtitle:
                        '${selectedScore.toStringAsFixed(1)} / ${_maxPerMonth.toStringAsFixed(0)} score'
                            '  •  Rekod Puasa: $recordedPuasaCount/30'
                            '  •  Tidak Puasa: $notPuasaCount hari',
                      ),

                      Tw.gap(Tw.s6),

                      // -------------------------
                      // DAY SUMMARY
                      // -------------------------
                      BreezeSectionHeader(
                        title: 'Ringkasan Hari',
                        subtitle:
                        'Semua rekod untuk Hari $selectedDay (Puasa, Solat, Tarawih, Sedekah, Sahur)',
                        icon: Icons.dashboard_rounded,
                        trailing: BreezePill(text: 'Hari $selectedDay', icon: Icons.today_rounded),
                      ),
                      Tw.gap(Tw.s3),
                      BreezeCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _pill(
                                context,
                                icon: Icons.nights_stay_rounded,
                                label: puasaLabel(todayPuasaVal, recorded: todayPuasaRecorded),
                                tone: Tone.primary,
                              ),
                              _pill(
                                context,
                                icon: Icons.mosque_rounded,
                                label: 'Solat: $todaySolatCount/5',
                                tone: Tone.secondary,
                              ),
                              _pill(
                                context,
                                icon: Icons.nightlight_round,
                                label: tarawihLabel(
                                  rakaat: todayTarawih,
                                  recorded: todayTarawihRecorded,
                                ),
                                tone: Tone.tertiary,
                              ),
                              _pill(
                                context,
                                icon: Icons.volunteer_activism_rounded,
                                label: boolLabel(
                                  v: todaySedekah,
                                  recorded: todaySedekahRecorded,
                                  trueText: 'Sedekah: Ya',
                                  falseText: 'Sedekah: Tidak',
                                ),
                                tone: Tone.neutral,
                              ),
                              _pill(
                                context,
                                icon: Icons.alarm_rounded,
                                label: boolLabel(
                                  v: todaySahur,
                                  recorded: todaySahurRecorded,
                                  trueText: 'Sahur: Bangun',
                                  falseText: 'Sahur: Tak Bangun',
                                ),
                                tone: Tone.neutral,
                              ),
                            ],
                          ),
                        ),
                      ),

                      Tw.gap(Tw.s6),

                      // -------------------------
                      // PUASA SECTION
                      // -------------------------
                      BreezeSectionHeader(
                        title: 'Puasa',
                        subtitle: 'Pilih Hari (grid) dan rekod status puasa.',
                        icon: Icons.calendar_month_rounded,
                        trailing: BreezePill(text: 'Hari $selectedDay', icon: Icons.today_rounded),
                      ),
                      Tw.gap(Tw.s3),

                      _dayGrid(
                        context: context,
                        selectedMemberId: selected,
                        selectedDay: selectedDay,
                        onSelectDay: (d) => setState(() => selectedDay = d),
                        fastingValue: (day) => fastingValue(selected, day),
                        isRecorded: (day) => isFastingRecorded(selected, day),
                      ),

                      Tw.gap(Tw.s4),

                      _sectionCard(
                        context: context,
                        titleLeft: 'Status Puasa',
                        titleRight: puasaLabel(todayPuasaVal, recorded: todayPuasaRecorded),
                        rightIcon: Icons.event_available_rounded,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final isNarrow = c.maxWidth < 560;

                            Widget button(String label, double value) {
                              final isSelected = todayPuasaRecorded && todayPuasaVal == value;
                              return SizedBox(
                                height: 44,
                                width: isNarrow ? double.infinity : 180,
                                child: OutlinedButton(
                                  onPressed: () async => onSetPuasa(value),
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
                              button('Tidak Puasa', 0.0),
                              button('Puasa Separuh', 0.5),
                              button('Puasa Penuh', 1.0),
                            ];

                            final reasonBox = (todayPuasaRecorded &&
                                todayPuasaVal == 0.0 &&
                                (todayPuasaReason?.trim().isNotEmpty ?? false))
                                ? Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant
                                    .withOpacity(0.25),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sebab: $todayPuasaReason',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).hintColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : const SizedBox.shrink();

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  reasonBox,
                                  ...buttons.expand((w) sync* {
                                    yield w;
                                    yield const SizedBox(height: 10);
                                  }).toList()
                                    ..removeLast(),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                reasonBox,
                                Wrap(spacing: 10, runSpacing: 10, children: buttons),
                              ],
                            );
                          },
                        ),
                      ),

                      Tw.gap(Tw.s6),

                      // -------------------------
                      // SOLAT SECTION
                      // -------------------------
                      BreezeSectionHeader(
                        title: 'Solat (Hari $selectedDay)',
                        subtitle: 'Tandakan solat yang telah dibuat.',
                        icon: Icons.mosque_rounded,
                        trailing: BreezePill(
                          text: '$todaySolatCount / 5',
                          icon: Icons.fact_check_rounded,
                        ),
                      ),
                      Tw.gap(Tw.s3),

                      _sectionCard(
                        context: context,
                        titleLeft: 'Status Solat',
                        titleRight: missingSolatLabel(selected, selectedDay),
                        rightIcon: Icons.checklist_rounded,
                        child: _solatGrid(
                          context: context,
                          selectedMemberId: selected,
                          selectedDay: selectedDay,
                          prayers: _prayers,
                          isDone: (key) => isSolatDone(selected, selectedDay, key),
                          onToggle: (key) async {
                            final mem = members.firstWhere((m) => m.id == selected);
                            final current = isSolatDone(selected, selectedDay, key);
                            await fasting.setSolat(
                              uid: profile.uid,
                              year: _year,
                              memberId: mem.id,
                              memberName: mem.name,
                              day: selectedDay,
                              prayerKey: key,
                              value: !current,
                            );
                          },
                        ),
                      ),

                      Tw.gap(Tw.s6),

                      // -------------------------
                      // TARAWIH SECTION (8 / 12)
                      // -------------------------
                      BreezeSectionHeader(
                        title: 'Tarawih (Hari $selectedDay)',
                        subtitle: 'Pilih 8 atau 20 rakaat.',
                        icon: Icons.nightlight_round,
                        trailing: BreezePill(
                          text: todayTarawihRecorded
                              ? '${todayTarawih ?? '-'} rakaat'
                              : 'Belum Rekod',
                          icon: Icons.star_rounded,
                        ),
                      ),
                      Tw.gap(Tw.s3),

                      _sectionCard(
                        context: context,
                        titleLeft: 'Rekod Tarawih',
                        titleRight: tarawihLabel(
                          rakaat: todayTarawih,
                          recorded: todayTarawihRecorded,
                        ),
                        rightIcon: Icons.night_shelter_rounded,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final isNarrow = c.maxWidth < 560;

                            Widget button(String label, int rakaat) {
                              final isSelected = todayTarawihRecorded && todayTarawih == rakaat;
                              return SizedBox(
                                height: 44,
                                width: isNarrow ? double.infinity : 180,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final mem = members.firstWhere((m) => m.id == selected);
                                    await fasting.setTarawihRakaat(
                                      uid: profile.uid,
                                      year: _year,
                                      memberId: mem.id,
                                      memberName: mem.name,
                                      day: selectedDay,
                                      rakaat: rakaat,
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
                              button('8 Rakaat', 8),
                              button('20 Rakaat', 20),
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

                            return Wrap(spacing: 10, runSpacing: 10, children: buttons);
                          },
                        ),
                      ),

                      Tw.gap(Tw.s6),

                      // -------------------------
                      // SEDEKAH SECTION (YA/TIDAK)
                      // -------------------------
                      BreezeSectionHeader(
                        title: 'Sedekah (Hari $selectedDay)',
                        subtitle: 'Rekod sama ada telah bersedekah atau tidak.',
                        icon: Icons.volunteer_activism_rounded,
                        trailing: BreezePill(
                          text: boolLabel(
                            v: todaySedekah,
                            recorded: todaySedekahRecorded,
                            trueText: 'Ya',
                            falseText: 'Tidak',
                          ),
                          icon: Icons.favorite_rounded,
                        ),
                      ),
                      Tw.gap(Tw.s3),

                      _sectionCard(
                        context: context,
                        titleLeft: 'Rekod Sedekah',
                        titleRight: boolLabel(
                          v: todaySedekah,
                          recorded: todaySedekahRecorded,
                          trueText: 'Sedekah: Ya',
                          falseText: 'Sedekah: Tidak',
                        ),
                        rightIcon: Icons.handshake_rounded,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final isNarrow = c.maxWidth < 560;

                            Widget button(String label, bool value) {
                              final isSelected = todaySedekahRecorded && todaySedekah == value;
                              return SizedBox(
                                height: 44,
                                width: isNarrow ? double.infinity : 180,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final mem = members.firstWhere((m) => m.id == selected);
                                    await fasting.setSedekah(
                                      uid: profile.uid,
                                      year: _year,
                                      memberId: mem.id,
                                      memberName: mem.name,
                                      day: selectedDay,
                                      value: value,
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
                              button('Ya, Bersedekah', true),
                              button('Tidak', false),
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

                            return Wrap(spacing: 10, runSpacing: 10, children: buttons);
                          },
                        ),
                      ),

                      Tw.gap(Tw.s6),

                      // -------------------------
                      // SAHUR SECTION (BANGUN/TIDAK)
                      // -------------------------
                      BreezeSectionHeader(
                        title: 'Sahur (Hari $selectedDay)',
                        subtitle: 'Rekod sama ada bangun sahur atau tidak.',
                        icon: Icons.alarm_rounded,
                        trailing: BreezePill(
                          text: boolLabel(
                            v: todaySahur,
                            recorded: todaySahurRecorded,
                            trueText: 'Bangun',
                            falseText: 'Tak Bangun',
                          ),
                          icon: Icons.notifications_active_rounded,
                        ),
                      ),
                      Tw.gap(Tw.s3),

                      _sectionCard(
                        context: context,
                        titleLeft: 'Rekod Sahur',
                        titleRight: boolLabel(
                          v: todaySahur,
                          recorded: todaySahurRecorded,
                          trueText: 'Sahur: Bangun',
                          falseText: 'Sahur: Tak Bangun',
                        ),
                        rightIcon: Icons.alarm_on_rounded,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final isNarrow = c.maxWidth < 560;

                            Widget button(String label, bool value) {
                              final isSelected = todaySahurRecorded && todaySahur == value;
                              return SizedBox(
                                height: 44,
                                width: isNarrow ? double.infinity : 180,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final mem = members.firstWhere((m) => m.id == selected);
                                    await fasting.setSahur(
                                      uid: profile.uid,
                                      year: _year,
                                      memberId: mem.id,
                                      memberName: mem.name,
                                      day: selectedDay,
                                      value: value,
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
                              button('Bangun Sahur', true),
                              button('Tak Bangun', false),
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

                            return Wrap(spacing: 10, runSpacing: 10, children: buttons);
                          },
                        ),
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

  List<({String id, String name})> _buildMembers(UserProfile profile) {
    final members = <({String id, String name})>[];

    if (profile.planType == PlanType.solo) {
      final fallbackName = profile.parents.isNotEmpty ? profile.parents.first : 'Self';
      members.add((id: 'self', name: fallbackName));
      return members;
    }

    for (var i = 0; i < profile.parents.length; i++) {
      members.add((id: 'parent_$i', name: profile.parents[i]));
    }
    for (var i = 0; i < profile.children.length; i++) {
      members.add((id: 'child_$i', name: profile.children[i]));
    }

    return members;
  }

  Future<String?> _showTidakPuasaReasonDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TidakPuasaReasonDialog(),
    );
  }

  static Widget _sectionCard({
    required BuildContext context,
    required String titleLeft,
    required String titleRight,
    required IconData rightIcon,
    required Widget child,
  }) {
    return BreezeCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  Icon(rightIcon, size: 18, color: Theme.of(context).colorScheme.primary),
                  Text(
                    titleLeft,
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
                      titleRight,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  static Widget _dayGrid({
    required BuildContext context,
    required String selectedMemberId,
    required int selectedDay,
    required void Function(int day) onSelectDay,
    required double Function(int day) fastingValue,
    required bool Function(int day) isRecorded,
  }) {
    return LayoutBuilder(
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

            final val = fastingValue(day);
            final recorded = isRecorded(day);
            final isSelected = day == selectedDay;

            final icon = !recorded
                ? Icons.help_outline_rounded
                : (val >= 1.0
                ? Icons.nights_stay_rounded
                : (val >= 0.5
                ? Icons.brightness_5_rounded
                : Icons.cancel_rounded));

            final chip = BreezeToggleChip(
              label: 'Hari $day',
              checked: recorded,
              icon: icon,
              onTap: () => onSelectDay(day),
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
    );
  }

  static Widget _solatGrid({
    required BuildContext context,
    required String selectedMemberId,
    required int selectedDay,
    required List<({String key, String label, IconData icon})> prayers,
    required bool Function(String prayerKey) isDone,
    required Future<void> Function(String prayerKey) onToggle,
  }) {
    return LayoutBuilder(
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
          itemCount: prayers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, i) {
            final p = prayers[i];
            final checked = isDone(p.key);

            return BreezeToggleChip(
              label: p.label,
              checked: checked,
              icon: p.icon,
              onTap: () async => onToggle(p.key),
            );
          },
        );
      },
    );
  }

  static Widget _pill(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Tone tone,
      }) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    Color border;

    switch (tone) {
      case Tone.primary:
        bg = cs.primary.withOpacity(0.10);
        fg = cs.primary;
        border = cs.primary.withOpacity(0.25);
        break;
      case Tone.secondary:
        bg = cs.secondary.withOpacity(0.10);
        fg = cs.secondary;
        border = cs.secondary.withOpacity(0.25);
        break;
      case Tone.tertiary:
        bg = cs.tertiary.withOpacity(0.10);
        fg = cs.tertiary;
        border = cs.tertiary.withOpacity(0.25);
        break;
      case Tone.neutral:
        bg = cs.surfaceVariant.withOpacity(0.35);
        fg = cs.onSurfaceVariant;
        border = cs.outlineVariant.withOpacity(0.55);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
