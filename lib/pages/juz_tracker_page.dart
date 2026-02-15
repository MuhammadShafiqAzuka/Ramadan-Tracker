import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadhan_hero/models/plan_type.dart';

import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/quran_service.dart';
import '../utils/tw.dart';
import '../widgets/breeze_ui.dart';

class JuzTrackerPage extends ConsumerStatefulWidget {
  const JuzTrackerPage({super.key, this.year});
  final int? year;

  @override
  ConsumerState<JuzTrackerPage> createState() => _JuzTrackerPageState();
}

class _JuzTrackerPageState extends ConsumerState<JuzTrackerPage> {
  String? selectedMemberId;
  int get _year => widget.year ?? DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('Profile missing.')));

        final members = <({String id, String name})>[];
        if (profile.planType.id == 'solo') {
          final name = profile.parents.isNotEmpty ? profile.parents.first : 'Self';
          members.add((id: 'self', name: name));
        } else {
          for (var i = 0; i < profile.parents.length; i++) {
            members.add((id: 'parent_$i', name: profile.parents[i]));
          }
          for (var i = 0; i < profile.children.length; i++) {
            members.add((id: 'child_$i', name: profile.children[i]));
          }
        }

        final selected = selectedMemberId ?? (members.isNotEmpty ? members.first.id : null);

        final yearAsync = ref.watch(ramadhanYearProvider((uid: profile.uid, year: _year)));
        final quran = ref.read(quranServiceProvider);

        return yearAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Failed: $e'))),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};

            bool isDone(String memberId, int juz) {
              final m = membersData[memberId] as Map<String, dynamic>?;
              final juzMap = m?['juz'] as Map<String, dynamic>?;

              final node = juzMap?['$juz'];
              if (node == true) return true; // ✅ old data
              if (node is Map) return node['done'] == true; // ✅ new data
              return false;
            }

            int countDone(String memberId) {
              var done = 0;
              for (var j = 1; j <= 30; j++) {
                if (isDone(memberId, j)) done++;
              }
              return done;
            }

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
              title: 'Penjejak Juzuk Quran ($_year)',
              onLogout: () async => ref.read(authServiceProvider).logout(),
              body: SingleChildScrollView(
                padding: Tw.p(Tw.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BreezeSectionHeader(
                    //   title: 'Keseluruhan',
                    //   subtitle: 'Jejaki 30 juz completion setiap ahli isi rumah',
                    //   icon: Icons.dashboard_rounded,
                    //   trailing: BreezePill(
                    //     text: '${(overall * 100).round()}%  •  $doneCells / $totalCells',
                    //     icon: Icons.menu_book_outlined,
                    //   ),
                    // ),
                    // Tw.gap(Tw.s3),
                    // BreezeProgressBlock(
                    //   title: 'Progress Isi Rumah',
                    //   value: overall,
                    //   rightText: '${(overall * 100).round()}%',
                    //   subtitle: '$doneCells ticks out of $totalCells total',
                    // ),
                    //
                    // Tw.gap(Tw.s5),

                    BreezeSectionHeader(
                      title: 'Ahli',
                      subtitle: 'Pilih ahli keluarga yang anda mahu kemas kini',
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
                        subtitle: '$selectedDone / 30 juz',
                      ),
                      Tw.gap(Tw.s5),

                      BreezeSectionHeader(
                        title: 'Juzuk',
                        subtitle: 'Markah = Juzuk (0-30) untuk 1 hari',
                        icon: Icons.menu_book_rounded,
                        trailing: BreezePill(text: '1–30', icon: Icons.tune_rounded),
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
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              childAspectRatio: 1.8,
                            ),
                            itemBuilder: (context, idx) {
                              final j = idx + 1;
                              final checked = isDone(selected, j);

                              return BreezeToggleChip(
                                label: 'Juzuk $j',
                                checked: checked,
                                onTap: () async {
                                  final current = isDone(selected, j);
                                  final mem = members.firstWhere((m) => m.id == selected);
                                  await quran.setJuz(
                                    uid: profile.uid,
                                    year: _year,
                                    memberId: mem.id,
                                    memberName: mem.name,
                                    juz: j,
                                    value: !current,
                                  );
                                },
                                icon: Icons.bookmark_added_rounded,
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