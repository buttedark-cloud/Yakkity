import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/session_events.dart';
import 'core/theme/app_theme.dart';
import 'di.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/ui/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDi();
  runApp(const YakkityApp());
}

class YakkityApp extends StatelessWidget {
  const YakkityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(getIt<AuthRepository>(), getIt<SessionEvents>())..start(),
      child: MaterialApp(title: 'Yakkity', theme: AppTheme.light(), home: const AuthGate()),
    );
  }
}
