import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/auth/cubit/auth_state.dart';
import 'package:yakkity/features/auth/ui/chats_page.dart';

import 'code_page.dart';
import 'phone_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
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
    );
  }
}
