import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadhan_hero/models/plan_type.dart';
import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/surah_service.dart';
import '../utils/surah_list.dart';
import '../utils/tw.dart';
import '../utils/date_key.dart';
import '../widgets/breeze_ui.dart';

class SurahTrackerPage extends ConsumerStatefulWidget {
  const SurahTrackerPage({super.key, this.year});
  final int? year;

  @override
  ConsumerState<SurahTrackerPage> createState() => _SurahTrackerPageState();
}

class _SurahTrackerPageState extends ConsumerState<SurahTrackerPage> {
  String? selectedMemberId;
  String q = '';
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
        final surahSvc = ref.read(surahServiceProvider);
        final today = isoDayKey(DateTime.now());

        return yearAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Failed: $e'))),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic>? memberNode(String memberId) {
              return membersData[memberId] as Map<String, dynamic>?;
            }

            // surah_tracker_page.dart (only the read helpers changed)
            bool recitedToday(String memberId, int surahNo) {
              final m = memberNode(memberId);
              final surahMap = m?['surah'] as Map<String, dynamic>?;
              final surahNode = surahMap?['$surahNo'] as Map<String, dynamic>?;
              final dates = (surahNode?['dateRecited'] as List?)?.cast<String>() ?? <String>[];
              return dates.contains(today);
            }

            int timesRecited(String memberId, int surahNo) {
              final m = memberNode(memberId);
              final surahMap = m?['surah'] as Map<String, dynamic>?;
              final surahNode = surahMap?['$surahNo'] as Map<String, dynamic>?;
              final dates = (surahNode?['dateRecited'] as List?)?.cast<String>() ?? <String>[];
              return dates.length;
            }

            final filtered = <(int no, String name)>[];
            final qq = q.trim().toLowerCase();
            for (var i = 0; i < surahNames.length; i++) {
              final no = i + 1;
              final name = surahNames[i];
              if (qq.isEmpty || name.toLowerCase().contains(qq) || '$no'.contains(qq)) {
                filtered.add((no, name));
              }
            }

            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            return BreezeWebScaffold(
              title: 'Penjejak Surah ($_year)',
              onLogout: () async => ref.read(authServiceProvider).logout(),
              body: Padding(
                padding: Tw.p(Tw.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BreezeSectionHeader(
                      title: 'Setup',
                      subtitle: 'Pilih ahli dan cari surah',
                      icon: Icons.tune_rounded,
                      trailing: BreezePill(text: 'Today: $today', icon: Icons.today_rounded),
                    ),
                    Tw.gap(Tw.s3),

                    BreezeMemberSelector(
                      members: members,
                      value: selected,
                      onChanged: (v) => setState(() => selectedMemberId = v),
                    ),
                    Tw.gap(Tw.s3),

                    BreezeCard(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cari surah (nama atau nombor)',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => q = v),
                      ),
                    ),

                    Tw.gap(Tw.s4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tracking untuk $selectedName',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        BreezePill(text: '${filtered.length} result(s)', icon: Icons.list_rounded),
                      ],
                    ),
                    Tw.gap(Tw.s3),

                    Expanded(
                      child: BreezeCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final (no, name) = filtered[idx];
                            final doneToday = selected == null ? false : recitedToday(selected, no);
                            final count = selected == null ? 0 : timesRecited(selected, no);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                child: Text('$no', style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text('Masa direkodkan: $count'),
                              trailing: Icon(
                                doneToday ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: doneToday ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                              ),
                              onTap: selected == null
                                  ? null
                                  : () async {
                                final mem = members.firstWhere((m) => m.id == selected);
                                await surahSvc.toggleSurahDate(
                                  uid: profile.uid,
                                  year: _year,
                                  memberId: mem.id,
                                  memberName: mem.name,
                                  surah: no,
                                  isoDate: today,
                                  value: !doneToday,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
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
