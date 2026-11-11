import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:yakkity/features/chat/data/local_message_store.dart';

import 'core/network/chat_socket.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/network/api_client.dart';
import 'core/network/session_events.dart';
import 'core/storage/token_storage.dart';

import 'package:sembast/sembast.dart';

import 'core/storage/database_opener.dart';

final getIt = GetIt.instance;

Future<void> setupDi() async {
  getIt.registerSingleton<SessionEvents>(SessionEvents());
  getIt.registerSingleton<TokenStorage>(TokenStorage(const FlutterSecureStorage()));
  getIt.registerSingleton<Dio>(createDio(getIt<TokenStorage>(), getIt<SessionEvents>()));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(getIt<Dio>(), getIt<TokenStorage>()));
  getIt.registerSingleton<Database>(await openAppDatabase());
  getIt.registerLazySingleton<LocalMessageStore>(() => LocalMessageStore(getIt<Database>()));
  getIt.registerLazySingleton<ChatSocket>(() => ChatSocket(getIt<TokenStorage>(), getIt<SessionEvents>()));
  getIt.registerLazySingleton<ChatRepository>(() => ChatRepository(getIt<Dio>(), getIt<ChatSocket>(), getIt<LocalMessageStore>()));
}
