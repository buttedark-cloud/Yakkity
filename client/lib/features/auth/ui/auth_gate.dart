import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yakkity/features/chat/ui/chats_page.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/cubit/auth_state.dart';
import 'package:yakkity/features/auth/ui/code_page.dart';
import 'package:yakkity/features/auth/ui/phone_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      // Вышли или сессия истекла: закрываем все открытые чаты
      listenWhen: (prev, curr) => prev.status != curr.status && curr.status == AuthStatus.unauthenticated,
      listener: (context, _) => Navigator.of(context).popUntil((route) => route.isFirst),
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (prev, curr) => prev.status != curr.status || prev.step != curr.step,
        builder: (context, state) {
          switch (state.status) {
            case AuthStatus.checking:
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            case AuthStatus.authenticated:
              return const ChatsPage();
            case AuthStatus.unauthenticated:
              return state.step == AuthStep.code ? const CodePage() : const PhonePage();
          }
        },
      ),
    );
  }
}
