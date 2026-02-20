import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../common/utils/tw.dart';
import '../common/widgets/theme_toggle.dart';
import '../models/plan_type.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

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
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;
    final authLoading = authAsync.isLoading;

    final auth = ref.read(authServiceProvider);
    final profiles = ref.read(userProfileServiceProvider);

    final profileAsync = ref.watch(userProfileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Tw.darkBorder : Tw.slate200;

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
          // 1) auth still settling → wait
          if (authLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2) not logged in → wait for router redirect
          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 3) logged in but profile not loaded yet → give it a moment
          // (prevents the "missing profile until refresh" flash)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // just a small delay to allow first Firestore snapshot
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final plan = profile.planType;
        final planId = plan.id;

        final isSolo = planId == 'solo';
        final needParents = _requiresParents(planId);
        final childCount = _childrenCountForPlan(planId);

        final hasHousehold = profile.parents.isNotEmpty &&
            (planId == 'solo'
                ? true
                : (profile.parents.length >= 2 && profile.children.length >= childCount));

        if (hasHousehold) {
          // redirect after first frame (avoid calling go during build)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // hydrate fields from saved household (if any)
        _hydrateFromProfile(
          parents: profile.parents,
          children: profile.children,
          isSolo: isSolo,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Ramadan Hero • ${profile.planType.title}'),
            actions: [
              // Breeze-like small icon control area
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                  color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                ),
                child: const ThemeToggle(),
              ),
              TextButton(
                onPressed: () async => auth. logout(),
                child: const Text('Log keluar'),
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
                            ? 'Masuk nama anda untuk mula.'
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

                            if (isSolo) {
                              await profiles.saveSetup(
                                uid: profile.uid,
                                ownerName: _soloName.text.trim(),
                              );
                            } else {
                              await profiles.saveSetup(
                                uid: profile.uid,
                                parents: [_parent1.text.trim(), _parent2.text.trim()],
                                children: [
                                  for (var i = 0; i < childCount; i++) _children[i].text.trim(),
                                ],
                              );
                            }

                            if (mounted) context.go('/tracker-fasting');

                            setState(() => success = 'Berjaya disimpan ✅');
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
                        ) : const Text('Mula'),
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
