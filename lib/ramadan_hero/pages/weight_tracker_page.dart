import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/utils/date_key.dart';
import '../../common/utils/tw.dart';
import '../../common/widgets/breeze_ui.dart';
import '../models/plan_type.dart';
import '../providers/fasting_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/weight_service.dart';

class WeightTrackerPage extends ConsumerStatefulWidget {
  const WeightTrackerPage({super.key, this.year});
  final int? year;

  @override
  ConsumerState<WeightTrackerPage> createState() => _WeightTrackerPageState();
}

class _WeightTrackerPageState extends ConsumerState<WeightTrackerPage> {
  String? selectedMemberId;

  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _dailyCtrl = TextEditingController();

  int get _year => widget.year ?? DateTime.now().year;

  // ✅ Ramadan window dates by year (lock editing for checkpoints until these dates)
  ({DateTime start, DateTime end}) _ramadanWindow(int year) {
    // Hardcode per-year (easy + explicit).
    // Add more years as you need.
    switch (year) {
      case 2026:
        return (start: DateTime(2026, 2, 19), end: DateTime(2026, 3, 20));
      case 2025:
        return (start: DateTime(2025, 3, 1), end: DateTime(2025, 3, 30));
      case 2027:
        return (start: DateTime(2027, 2, 8), end: DateTime(2027, 3, 9));
      default:
      // ✅ Fallback (approx). You can change to "locked forever" if you prefer.
        return (start: DateTime(year, 3, 1), end: DateTime(year, 3, 30));
    }
  }

  bool _isOnOrAfter(DateTime d, DateTime min) {
    final dd = DateTime(d.year, d.month, d.day);
    final mm = DateTime(min.year, min.month, min.day);
    return !dd.isBefore(mm);
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _dailyCtrl.dispose();
    super.dispose();
  }

  double? _parseWeight(String s) {
    final t = s.trim().replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null) return null;
    if (v <= 0 || v > 400) return null;
    return v;
  }

  String _fmtKg(num? v) {
    if (v == null) return '-';
    final n = v.toDouble();
    return '${n.toStringAsFixed((n % 1 == 0) ? 0 : 1)} kg';
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

        // Members list
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

        final now = DateTime.now();
        final today = isoDayKey(now);

        // ✅ dynamic lock window based on year
        final window = _ramadanWindow(_year);
        final startEditableFrom = window.start;
        final endEditableFrom = window.end;

        // ✅ gates for checkpoints
        final canEditStart = _isOnOrAfter(now, startEditableFrom);
        final canEditEnd = _isOnOrAfter(now, endEditableFrom);

        return yearAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Failed: $e'))),
          data: (data) {
            final membersData = (data?['members'] as Map<String, dynamic>?) ?? {};
            final selectedNode =
            selected == null ? null : (membersData[selected] as Map<String, dynamic>?);

            final weightMap = (selectedNode?['weight'] as Map<String, dynamic>?) ?? {};
            final checkpointMap = (selectedNode?['weightCheckpoint'] as Map<String, dynamic>?) ?? {};

            final startW = checkpointMap['start'];
            final endW = checkpointMap['end'];

            final entries = weightMap.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

            final selectedName = members
                .firstWhere((m) => m.id == selected, orElse: () => (id: '', name: ''))
                .name;

            // Prefill checkpoint inputs (only if empty)
            if (_startCtrl.text.isEmpty && startW != null) _startCtrl.text = '$startW';
            if (_endCtrl.text.isEmpty && endW != null) _endCtrl.text = '$endW';

            // Prefill today's daily input if exists
            if (_dailyCtrl.text.isEmpty && weightMap[today] != null) {
              _dailyCtrl.text = '${weightMap[today]}';
            }

            final startVal = (startW is num) ? startW.toDouble() : null;
            final endVal = (endW is num) ? endW.toDouble() : null;
            final diff = (startVal != null && endVal != null) ? (endVal - startVal) : null;

            IconData? diffIcon;
            String? diffText;
            if (diff != null) {
              if (diff > 0) {
                diffIcon = Icons.trending_up_rounded;
                diffText = '+${diff.toStringAsFixed(1)} kg';
              } else if (diff < 0) {
                diffIcon = Icons.trending_down_rounded;
                diffText = '${diff.toStringAsFixed(1)} kg';
              } else {
                diffIcon = Icons.trending_flat_rounded;
                diffText = '0.0 kg';
              }
            }

            final hasStart = startVal != null;
            final hasEnd = endVal != null;
            final mandatoryDone = (hasStart ? 1 : 0) + (hasEnd ? 1 : 0);

            final mandatoryPill = BreezePill(
              text: '$mandatoryDone/2 wajib',
              icon: mandatoryDone == 2 ? Icons.verified_rounded : Icons.rule_rounded,
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
                      trailing: mandatoryPill,
                    ),
                    Tw.gap(Tw.s3),
                    BreezeMemberSelector(
                      members: members,
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          selectedMemberId = v;
                          _startCtrl.clear();
                          _endCtrl.clear();
                          _dailyCtrl.clear();
                        });
                      },
                    ),
                    Tw.gap(Tw.s6),

                    BreezeSectionHeader(
                      title: 'Wajib (2 kali sahaja)',
                      subtitle: 'Awal Ramadan boleh isi bermula ${_fmtDate(startEditableFrom)} • '
                          'Akhir Ramadan bermula ${_fmtDate(endEditableFrom)}',
                      icon: Icons.flag_rounded,
                      trailing: (diffText == null) ? null : BreezePill(text: diffText!, icon: diffIcon),
                    ),
                    Tw.gap(Tw.s3),

                    BreezeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _checkpointRow(
                            context,
                            title: 'Awal Ramadan',
                            subtitle: hasStart
                                ? 'Disimpan: ${_fmtKg(startVal)}'
                                : (canEditStart
                                ? 'Sila isi (dibuka)'
                                : 'Dibuka pada ${_fmtDate(startEditableFrom)}'),
                            icon: Icons.play_circle_fill_rounded,
                            controller: _startCtrl,
                            buttonText: hasStart ? 'Kemas kini' : 'Simpan',
                            enabled: canEditStart,
                            highlight: !canEditStart && !hasStart,
                            onSave: selected == null
                                ? null
                                : () async {
                              if (!canEditStart) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Awal Ramadan hanya boleh diisi bermula ${_fmtDate(startEditableFrom)}.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final v = _parseWeight(_startCtrl.text);
                              if (v == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Berat tidak sah. Contoh: 72.4')),
                                );
                                return;
                              }
                              final mem = members.firstWhere((m) => m.id == selected);
                              await weightSvc.setWeightCheckpoint(
                                uid: profile.uid,
                                year: _year,
                                memberId: mem.id,
                                memberName: mem.name,
                                key: 'start',
                                weight: v,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Awal Ramadan disimpan ✅')),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          Divider(color: Theme.of(context).dividerColor),
                          const SizedBox(height: 14),
                          _checkpointRow(
                            context,
                            title: 'Akhir Ramadan',
                            subtitle: hasEnd
                                ? 'Disimpan: ${_fmtKg(endVal)}'
                                : (canEditEnd
                                ? 'Sila isi (dibuka • wajib)'
                                : 'Dibuka pada ${_fmtDate(endEditableFrom)} (wajib)'),
                            icon: Icons.stop_circle_rounded,
                            controller: _endCtrl,
                            buttonText: hasEnd ? 'Kemas kini' : 'Simpan',
                            enabled: canEditEnd,
                            highlight: !hasEnd,
                            onSave: selected == null
                                ? null
                                : () async {
                              if (!canEditEnd) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Akhir Ramadan hanya boleh diisi bermula ${_fmtDate(endEditableFrom)}.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final v = _parseWeight(_endCtrl.text);
                              if (v == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Berat tidak sah. Contoh: 70.9')),
                                );
                                return;
                              }
                              final mem = members.firstWhere((m) => m.id == selected);
                              await weightSvc.setWeightCheckpoint(
                                uid: profile.uid,
                                year: _year,
                                memberId: mem.id,
                                memberName: mem.name,
                                key: 'end',
                                weight: v,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Akhir Ramadan disimpan ✅')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    Tw.gap(Tw.s6),

                    BreezeSectionHeader(
                      title: 'Hari Biasa',
                      subtitle: '$today • $selectedName',
                      icon: Icons.monitor_weight_rounded,
                      trailing: BreezePill(text: '${entries.length} jumlah', icon: Icons.list_rounded),
                    ),
                    Tw.gap(Tw.s3),

                    BreezeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _dailyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Berat hari ini (Kg)',
                              hintText: 'e.g. 72.4',
                              prefixIcon: Icon(Icons.scale_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: selected == null
                                ? null
                                : () async {
                              final v = _parseWeight(_dailyCtrl.text);
                              if (v == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Berat tidak sah. Contoh: 72.4')),
                                );
                                return;
                              }
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
                            child: const Text('Simpan (opsyenal)'),
                          ),
                        ],
                      ),
                    ),

                    Tw.gap(Tw.s6),

                    BreezeSectionHeader(
                      title: 'Sejarah',
                      subtitle: 'Entri terkini (maks 20)',
                      icon: Icons.history_rounded,
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
                                  style: const TextStyle(fontWeight: FontWeight.w900)),
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

  Widget _checkpointRow(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required TextEditingController controller,
        required String buttonText,
        required Future<void> Function()? onSave,
        required bool enabled,
        bool highlight = false,
      }) {
    final cs = Theme.of(context).colorScheme;
    final border = Theme.of(context).dividerColor;
    final hint = Theme.of(context).hintColor;

    final bg = highlight ? cs.error.withOpacity(0.06) : cs.primary.withOpacity(0.04);
    final iconColor = highlight ? cs.error : cs.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        color: bg,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 560;

          final field = TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: title,
              helperText: subtitle,
              helperStyle: TextStyle(
                color: enabled ? hint : hint.withOpacity(0.85),
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: Icon(icon, color: iconColor),
              suffixIcon: enabled ? null : Icon(Icons.lock_rounded, color: hint),
            ),
          );

          final btn = SizedBox(
            height: 44,
            width: isNarrow ? double.infinity : 160,
            child: FilledButton(
              onPressed: enabled ? onSave : null,
              style: FilledButton.styleFrom(
                backgroundColor: highlight ? cs.error : cs.primary,
                disabledBackgroundColor: Theme.of(context).dividerColor.withOpacity(0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(enabled ? buttonText : 'Terkunci'),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field,
                const SizedBox(height: 10),
                btn,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 12),
              btn,
            ],
          );
        },
      ),
    );
  }
}