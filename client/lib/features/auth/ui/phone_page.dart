import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/widgets/yakkity_logo.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/cubit/auth_state.dart';
import 'package:yakkity/features/auth/ui/auth_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:yakkity/core/config/app_config.dart';

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

  void _submit() => context.read<AuthCubit>().requestCode('+$_digits');

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: YakkityLogo(size: 52)),
              const SizedBox(height: AppSpacing.sm),
              Text('Введи номер телефона, и мы пришлём код', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: const InputDecoration(hintText: '+996 700 123 456', prefixIcon: Icon(Icons.phone_outlined)),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_valid && !state.loading) _submit();
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
                onPressed: (!_valid || state.loading) ? null : _submit,
                child: state.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Получить код'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Сервер: ${AppConfig.httpBase}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          );
        },
      ),
    );
  }
}
