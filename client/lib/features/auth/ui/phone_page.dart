import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final _controller = TextEditingController();

  String get _digits => _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
  bool get _valid => _digits.length >= 8;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Yakkity', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Введи номер телефона, чтобы войти', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'Номер телефона', hintText: '+996 700 123 456'),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) {
                          if (_valid && !state.loading) {
                            context.read<AuthCubit>().requestCode('+$_digits');
                          }
                        },
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: (!_valid || state.loading) ? null : () => context.read<AuthCubit>().requestCode('+$_digits'),
                        child: state.loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Получить код'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
