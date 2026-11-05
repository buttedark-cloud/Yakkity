import 'package:flint_dart/flint_dart.dart';
import 'package:messenger_backend/routes/app_routes.dart';
import 'package:messenger_backend/sockets/chat_socket.dart';

void main() {
  final app = Flint(
    withDefaultMiddleware: true,
    autoConnectDb: false,
    enableSwaggerDocs: true,
  );

  // Mount the main AppRoutes
  app.routes(AppRoutes());

  app.websocket('/ws/chat', chatSocket);

  // Start the server
  app.listen(hotReload: true);
}
