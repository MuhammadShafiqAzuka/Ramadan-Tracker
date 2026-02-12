import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/plan_type.dart';
import '../providers/profile_provider.dart';
import '../services/user_profile_service.dart';
import '../utils/tw.dart';
import '../widgets/theme_toggle.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _soloName = TextEditingController();
  final _parent1 = TextEditingController();
  final _parent2 = TextEditingController();
  final _children = List.generate(6, (_) => TextEditingController());

  bool _hydrated = false;
  bool saving = false;
  String? error;
  String? success;

  @override
  void dispose() {
    _soloName.dispose();
    _parent1.dispose();
    _parent2.dispose();
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  int _childrenCountForPlan(String planId) => switch (planId) {
    'five' => 3,
    'nine' => 6,
    _ => 0,
  };

  bool _requiresParents(String planId) => planId == 'five' || planId == 'nine';

  void _hydrateFromProfile({
    required bool isSolo,
    required List<String> parents,
    required List<String> children,
  }) {
    if (_hydrated) return;
    _hydrated = true;

    if (isSolo) {
      _soloName.text = parents.isNotEmpty ? parents.first : '';
      return;
    }

    _parent1.text = parents.isNotEmpty ? parents[0] : '';
    _parent2.text = parents.length > 1 ? parents[1] : '';

    for (var i = 0; i < _children.length; i++) {
      _children[i].text = children.length > i ? children[i] : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profiles = ref.read(userProfileServiceProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Tw.darkBorder : Tw.slate200;

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(child: Text('Failed to load profile: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final planId = profile.planType.id;
        final isSolo = planId == 'solo';
        final needParents = _requiresParents(planId);
        final childCount = _childrenCountForPlan(planId);

        _hydrateFromProfile(
          isSolo: isSolo,
          parents: profile.parents,
          children: profile.children,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Settings • ${profile.planType.title}'),
            actions: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(isDark ? 0.12 : 0.06),
                ),
                child: const ThemeToggle(),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: Tw.p(Tw.s8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'KEMASKINI NAMA',
                        style: Tw.title.copyWith(
                          color: isDark ? Tw.darkText : Tw.slate900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Tw.gap(Tw.s6),

                      if (isSolo) ...[
                        TextFormField(
                          controller: _soloName,
                          decoration: const InputDecoration(labelText: 'Nama'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nama perlukan';
                            return null;
                          },
                        ),
                      ],

                      if (needParents) ...[
                        TextFormField(
                          controller: _parent1,
                          decoration: const InputDecoration(labelText: 'Abah'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Abah diperlukan';
                            return null;
                          },
                        ),
                        Tw.gap(Tw.s4),
                        TextFormField(
                          controller: _parent2,
                          decoration: const InputDecoration(labelText: 'Ibu'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Ibu diperlukan';
                            return null;
                          },
                        ),
                        Tw.gap(Tw.s6),
                        Text(
                          'Anak - Anak ($childCount)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Tw.gap(Tw.s3),
                        for (var i = 0; i < childCount; i++) ...[
                          TextFormField(
                            controller: _children[i],
                            decoration: InputDecoration(labelText: 'Hero ${i + 1}'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Hero ${i + 1} diperlukan';
                              }
                              return null;
                            },
                          ),
                          if (i != childCount - 1) Tw.gap(Tw.s4),
                        ],
                      ],

                      if (error != null) ...[
                        Tw.gap(Tw.s4),
                        Text(error!, style: Tw.error),
                      ],
                      if (success != null) ...[
                        Tw.gap(Tw.s4),
                        Text(success!, style: const TextStyle(fontSize: 13)),
                      ],

                      Tw.gap(Tw.s8),
                      ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                          setState(() {
                            error = null;
                            success = null;
                            saving = true;
                          });

                          try {
                            if (!_formKey.currentState!.validate()) {
                              setState(() => saving = false);
                              return;
                            }

                            if (isSolo) {
                              await profiles.saveSetup(
                                uid: profile.uid,
                                ownerName: _soloName.text.trim(), // ✅ keep solo in ownerName
                              );
                            } else {
                              await profiles.saveSetup(
                                uid: profile.uid,
                                parents: [
                                  _parent1.text.trim(),
                                  _parent2.text.trim(),
                                ],
                                children: [
                                  for (var i = 0; i < childCount; i++)
                                    _children[i].text.trim(),
                                ],
                              );
                            }

                            if (!mounted) return;
                            setState(() => success = 'Berjaya dikemaskini ✅');
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => error = e.toString());
                          } finally {
                            if (!mounted) return;
                            setState(() => saving = false);
                          }
                        },
                        child: saving
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Simpan'),
                      ),

                      Tw.gap(Tw.s4),
                      OutlinedButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}