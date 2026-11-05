import 'package:flint_dart/flint_dart.dart';
import 'package:messenger_backend/routes/app_routes.dart';
import 'package:messenger_backend/sockets/chat_socket.dart';

void main() {
  final app = Flint(
    withDefaultMiddleware: true,
    autoConnectDb: false,
    enableSwaggerDocs: true,
  );

  // Разрешаем запросы из браузера (Flutter Web на другом порту)
  app.use(CorsMiddleware());

  app.routes(AppRoutes());
  app.websocket('/ws/chat', chatSocket);

  app.listen(hotReload: true);
}
