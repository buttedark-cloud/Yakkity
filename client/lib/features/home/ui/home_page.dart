import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakkity/di.dart';
import 'package:yakkity/features/auth/cubit/auth_cubit.dart';
import 'package:yakkity/features/chat/cubit/chats_cubit.dart';
import 'package:yakkity/features/chat/data/chat_repository.dart';
import 'package:yakkity/features/chat/ui/chats_page.dart';
import 'package:yakkity/features/home/ui/coming_soon_page.dart';
import 'package:yakkity/features/profile/ui/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = getIt<ChatRepository>();
  late final int _me;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Вошли в аккаунт: запускаем соединение с чатом
    _me = context.read<AuthCubit>().state.user!.id;
    unawaited(_repo.start(_me));
  }

  @override
  void dispose() {
    // Вышли из аккаунта: закрываем соединение
    unawaited(_repo.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatsCubit(_repo, _me),
      child: Scaffold(
        // IndexedStack хранит все вкладки живыми: при переключении
        // список чатов не перезагружается и не теряет положение прокрутки
        body: IndexedStack(
          index: _index,
          children: const [
            ChatsPage(),
            ComingSoonPage(title: 'Звонки', icon: Icons.call_outlined, text: 'Голосовые звонки появятся в одной из следующих версий'),
            ComingSoonPage(title: 'Контакты', icon: Icons.people_outline, text: 'Список контактов появится в одной из следующих версий'),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Чаты'),
            NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Звонки'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Контакты'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
          ],
        ),
      ),
    );
  }
}
