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
  int get _year => widget.year ?? DateTime.now().year;

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

            bool isFasted(String memberId, int day) {
              final m = membersData[memberId] as Map<String, dynamic>?;
              final fastingMap = m?['fasting'] as Map<String, dynamic>?;
              return fastingMap?['$day'] == true;
            }

            int countDone(String memberId) {
              var done = 0;
              for (var d = 1; d <= 30; d++) {
                if (isFasted(memberId, d)) done++;
              }
              return done;
            }

            // Household overall progress
            final totalCells = members.length * 30;
            var doneCells = 0;
            for (final mem in members) {
              doneCells += countDone(mem.id);
            }
            final overall = totalCells == 0 ? 0.0 : doneCells / totalCells;

            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            final selectedDone = selected == null ? 0 : countDone(selected);
            final selectedProgress = selected == null ? 0.0 : selectedDone / 30.0;

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
                      subtitle: 'Completion isi rumah di bulan Ramadhan Hari 1 - Hari 30',
                      icon: Icons.dashboard_rounded,
                      trailing: BreezePill(
                        text: '${(overall * 100).round()}%  •  $doneCells / $totalCells',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    Tw.gap(Tw.s3),
                    BreezeProgressBlock(
                      title: 'Progress Isi Rumah',
                      value: overall,
                      rightText: '${(overall * 100).round()}%',
                      subtitle: '$doneCells ticks out of $totalCells total',
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
                      onChanged: (v) => setState(() => selectedMemberId = v),
                    ),

                    Tw.gap(Tw.s5),

                    if (selected != null) ...[
                      BreezeProgressBlock(
                        title: 'Progress untuk $selectedName',
                        value: selectedProgress,
                        rightText: '${(selectedProgress * 100).round()}%',
                        subtitle: '$selectedDone / 30 days',
                      ),
                      Tw.gap(Tw.s5),

                      BreezeSectionHeader(
                        title: 'Hari',
                        subtitle: 'Klik untuk toggle hari puasa',
                        icon: Icons.calendar_month_rounded,
                        trailing: BreezePill(text: 'D1–D30', icon: Icons.tune_rounded),
                      ),
                      Tw.gap(Tw.s3),

                      // ✅ Web-friendly grid instead of Wrap (more consistent spacing)
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
                              final checked = isFasted(selected, day);

                              return BreezeToggleChip(
                                label: 'Hari $day',
                                checked: checked,
                                onTap: () async {
                                  final current = isFasted(selected, day);
                                  final mem = members.firstWhere((m) => m.id == selected);

                                  await fasting.setFastingDay(
                                    uid: profile.uid,
                                    year: _year,
                                    memberId: mem.id,
                                    memberName: mem.name,
                                    day: day,
                                    value: !current,
                                  );
                                },
                                icon: Icons.nights_stay_rounded,
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