import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadhan_hero/models/plan_type.dart';
import 'package:ramadhan_hero/widgets/breeze_ui.dart';

import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/weight_service.dart';
import '../utils/date_key.dart';
import '../utils/tw.dart';

class WeightTrackerPage extends ConsumerStatefulWidget {
  const WeightTrackerPage({super.key, this.year});
  final int? year;

  @override
  ConsumerState<WeightTrackerPage> createState() => _WeightTrackerPageState();
}

class _WeightTrackerPageState extends ConsumerState<WeightTrackerPage> {
  String? selectedMemberId;
  final _weight = TextEditingController();
  int get _year => widget.year ?? DateTime.now().year;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

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
        final weightSvc = ref.read(weightServiceProvider);
        final today = isoDayKey(DateTime.now());

        return yearAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Failed: $e'))),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};
            final selectedNode = selected == null ? null : (membersData[selected] as Map<String, dynamic>?);
            final weightMap = (selectedNode?['weight'] as Map<String, dynamic>?) ?? {};

            // sort dates desc
            final entries = weightMap.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            // prefill today's weight if exists
            if (_weight.text.isEmpty && weightMap[today] != null) {
              _weight.text = '${weightMap[today]}';
            }

            // latest vs previous (most recent change)
            double? latestW;
            String? latestD;
            double? prevW;
            String? prevD;

            if (entries.isNotEmpty) {
              latestD = entries[0].key;
              latestW = (entries[0].value as num).toDouble();
            }
            if (entries.length >= 2) {
              prevD = entries[1].key;
              prevW = (entries[1].value as num).toDouble();
            }

            final diff = (latestW != null && prevW != null) ? (latestW - prevW) : null;

            IconData? trendIcon;
            String? trendText;

            if (diff != null) {
              if (diff > 0) {
                trendIcon = Icons.trending_up_rounded;
                trendText = '+${diff.toStringAsFixed(1)} kg';
              } else if (diff < 0) {
                trendIcon = Icons.trending_down_rounded;
                trendText = '${diff.toStringAsFixed(1)} kg'; // already negative
              } else {
                trendIcon = Icons.trending_flat_rounded;
                trendText = '0.0 kg';
              }
            }

            // Optional: show baseline info in tooltip-ish style? (web)
            final trendPill = (trendText == null)
                ? null
                : BreezePill(
              text: trendText,
              icon: trendIcon,
            );

            return BreezeWebScaffold(
              title: 'Penjejak Berat ($_year)',
              onLogout: () async => ref.read(authServiceProvider).logout(),
              body: SingleChildScrollView(
                padding: Tw.p(Tw.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BreezeSectionHeader(
                      title: 'Ahli',
                      subtitle: 'Pilih orang yang anda mahu kemas kini',
                      icon: Icons.people_alt_rounded,
                      trailing: trendPill,
                    ),
                    Tw.gap(Tw.s3),
                    BreezeMemberSelector(
                      members: members,
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          selectedMemberId = v;
                          _weight.clear();
                        });
                      },
                    ),
                    Tw.gap(Tw.s5),
                    BreezeSectionHeader(
                      title: 'Hari ini',
                      subtitle: '$today • $selectedName',
                      icon: Icons.monitor_weight_rounded,
                    ),
                    Tw.gap(Tw.s3),
                    BreezeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _weight,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Berat (Kg)',
                              hintText: 'e.g. 72.4',
                              prefixIcon: Icon(Icons.scale_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: selected == null
                                ? null
                                : () async {
                              final v = double.tryParse(_weight.text.trim());
                              if (v == null) return;

                              final mem = members.firstWhere((m) => m.id == selected);
                              await weightSvc.setWeight(
                                uid: profile.uid,
                                year: _year,
                                memberId: mem.id,
                                memberName: mem.name,
                                isoDate: today,
                                weight: v,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Simpan ✅')),
                                );
                              }
                            },
                            child: const Text('Simpan berat'),
                          ),
                        ],
                      ),
                    ),
                    Tw.gap(Tw.s6),
                    BreezeSectionHeader(
                      title: 'Sejarah',
                      subtitle: 'Entri terkini',
                      icon: Icons.history_rounded,
                      trailing: BreezePill(text: '${entries.length} jumlah', icon: Icons.list_rounded),
                    ),
                    Tw.gap(Tw.s3),
                    if (entries.isEmpty)
                      BreezeCard(
                        child: Text(
                          'Tiada catatan berat lagi.',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      )
                    else
                      BreezeCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entries.length > 20 ? 20 : entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = entries[i];
                            return ListTile(
                              leading: const Icon(Icons.calendar_today_rounded, size: 18),
                              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800)),
                              trailing: Text(
                                '${e.value} Kg',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            );
                          },
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
