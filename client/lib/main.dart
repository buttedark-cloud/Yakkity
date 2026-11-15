import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/core/network/session_events.dart';
import 'package:yakkity/core/theme/app_theme.dart';
import 'package:yakkity/core/theme/theme_cubit.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/data/auth_repository.dart';
import 'package:yakkity/features/auth/ui/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDi();
  // Читаем сохранённую тему до первого кадра, чтобы не мигало
  await getIt<ThemeCubit>().load();
  runApp(const YakkityApp());
}

class YakkityApp extends StatelessWidget {
  const YakkityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider(create: (_) => AuthCubit(getIt<AuthRepository>(), getIt<SessionEvents>())..start()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) =>
            MaterialApp(title: 'Yakkity', theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: mode, home: const AuthGate()),
      ),
    );
  }
}
