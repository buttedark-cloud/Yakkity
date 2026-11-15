import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/cubit/auth_state.dart';
import 'package:yakkity/features/auth/ui/auth_shell.dart';

class CodePage extends StatefulWidget {
  const CodePage({super.key});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      onBack: () => context.read<AuthCubit>().backToPhone(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Введи код', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Код отправлен на ${state.phone}', textAlign: TextAlign.center),
              // Только для разработки: пока нет настоящих SMS
              if (state.devCode != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Код для разработки: ${state.devCode}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
              ],
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 10),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (_) => setState(() {}),
                onSubmitted: (v) {
                  if (v.length == 6 && !state.loading) {
                    context.read<AuthCubit>().verifyCode(v);
                  }
                },
              ),
              if (state.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: (_controller.text.length != 6 || state.loading)
                    ? null
                    : () => context.read<AuthCubit>().verifyCode(_controller.text),
                child: state.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Подтвердить'),
              ),
            ],
          );
        },
      ),
    );
  }
}
