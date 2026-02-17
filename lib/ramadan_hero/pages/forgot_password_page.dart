import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../common/utils/tw.dart';
import '../../common/widgets/auth_card.dart';
import '../services/auth_service.dart';


class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool loading = false;
  String? error;
  String? success;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return AuthCard(
      title: 'Tetapkan Semula Kata Laluan',
      subtitle: 'Kami akan menghantar pautan tetapan semula kepada anda melalui email',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email diperlukan';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            if (error != null) ...[
              Tw.gap(Tw.s3),
              Text(error!, style: Tw.error),
            ],
            if (success != null) ...[
              Tw.gap(Tw.s3),
              Text(success!, style: const TextStyle(fontSize: 13)),
            ],
            Tw.gap(Tw.s6),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                setState(() {
                  error = null;
                  success = null;
                  loading = true;
                });

                try {
                  if (!_formKey.currentState!.validate()) {
                    setState(() => loading = false);
                    return;
                  }

                  await auth.sendResetEmail(email: _email.text.trim());
                  setState(() => success = 'Tetapkan semula pautan dihantar. Semak email anda.');
                } catch (e) {
                  setState(() => error = e.toString());
                } finally {
                  setState(() => loading = false);
                }
              },
              child: loading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Hantar'),
            ),
            Tw.gap(Tw.s4),
          ],
        ),
      ),
    );
  }
}
