import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadhan_hero/models/plan_type.dart';

import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../utils/tw.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers (max needed)
  final _soloName = TextEditingController();

  final _parent1 = TextEditingController();
  final _parent2 = TextEditingController();

  final _children = List.generate(6, (_) => TextEditingController());

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

  void _hydrateFromProfile({
    required List<String> parents,
    required List<String> children,
    required bool isSolo,
  }) {
    // Only hydrate once per session to avoid overwriting typing
    if (_hydrated) return;
    _hydrated = true;

    if (isSolo) {
      _soloName.text = (parents.isNotEmpty ? parents.first : '');
      return;
    }

    _parent1.text = parents.isNotEmpty ? parents[0] : '';
    _parent2.text = parents.length > 1 ? parents[1] : '';

    for (var i = 0; i < _children.length; i++) {
      _children[i].text = children.length > i ? children[i] : '';
    }
  }

  bool _hydrated = false;

  int _childrenCountForPlan(String planId) => switch (planId) {
    'five' => 3,
    'nine' => 6,
    _ => 0,
  };

  bool _requiresParents(String planId) => planId == 'five' || planId == 'nine';

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);

    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(child: Text('Failed to load profile: $e')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account Setup'),
              actions: [
                TextButton(
                  onPressed: () async => auth.logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
            body: const Center(
              child: Text(
                'Your profile is missing.\n'
                    'Please sign up again using your purchase link.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final plan = profile.planType;
        final planId = plan.id;

        final isSolo = planId == 'solo';
        final needParents = _requiresParents(planId);
        final childCount = _childrenCountForPlan(planId);

        // hydrate fields from saved household (if any)
        _hydrateFromProfile(
          parents: profile.parents,
          children: profile.children,
          isSolo: isSolo,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Ramadan Tracker (${plan.title})'),
            actions: [
              TextButton(
                onPressed: () async => auth.logout(),
                child: const Text('Logout'),
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
                        'RAMADAN HERO',
                        style: Tw.title.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Tw.darkText
                              : Tw.slate900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Tw.gap(Tw.s3),
                      Text(
                        'Jurnal Ibadah Keluarga Rabbani',
                        style: Tw.title.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Tw.darkText
                              : Tw.slate900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Tw.gap(Tw.s6),
                      Text(
                        isSolo
                            ? 'Masuk nama untuk mula.'
                            : 'Masuk nama ketua dan pasangan untuk mula.',
                        style: Tw.subtitle.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Tw.darkSubtext
                              : Tw.slate700,
                        ),
                      ),
                      Tw.gap(Tw.s6),

                      if (isSolo) ...[
                        TextFormField(
                          controller: _soloName,
                          decoration: const InputDecoration(labelText: 'Your name'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                      ],

                      if (needParents) ...[
                        TextFormField(
                          controller: _parent1,
                          decoration: const InputDecoration(labelText: 'Abah'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Abah is required';
                            return null;
                          },
                        ),
                        Tw.gap(Tw.s4),
                        TextFormField(
                          controller: _parent2,
                          decoration: const InputDecoration(labelText: 'Ibu'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Ibu is required';
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
                                return 'Hero ${i + 1} is required';
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

                            // Build payload by plan
                            final parents = <String>[];
                            final children = <String>[];

                            if (isSolo) {
                              parents.add(_soloName.text.trim());
                            } else {
                              parents.add(_parent1.text.trim());
                              parents.add(_parent2.text.trim());
                              for (var i = 0; i < childCount; i++) {
                                children.add(_children[i].text.trim());
                              }
                            }

                            await profiles.saveHousehold(
                              uid: profile.uid,
                              planType: plan,
                              parents: parents,
                              children: children,
                            );

                            setState(() => success = 'Saved successfully ✅');
                          } catch (e) {
                            setState(() => error = e.toString());
                          } finally {
                            setState(() => saving = false);
                          }
                        },
                        child: saving
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('MULA'),
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
