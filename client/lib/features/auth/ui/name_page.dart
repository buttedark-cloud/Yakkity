import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/cubit/auth_state.dart';

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final _controller = TextEditingController();

  bool get _valid => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_valid) context.read<AuthCubit>().saveName(_controller.text.trim());
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
                      Text('Давай знакомиться', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('Как тебя зовут? Это имя увидят собеседники', textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Имя'),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (state.error != null)
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: (!_valid || state.loading) ? null : _submit,
                        child: state.loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Продолжить'),
                      ),
                      TextButton(onPressed: () => context.read<AuthCubit>().logout(), child: const Text('Выйти')),
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
