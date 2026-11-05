import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';

import 'package:yakkity/features/auth/cubit/auth_state.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Выйти', onPressed: () => context.read<AuthCubit>().logout())],
      ),
      body: Center(child: Text('Ты вошла как ${user?.phone}')),
    );
  }
}
