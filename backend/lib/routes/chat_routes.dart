import 'package:flint_dart/flint_dart.dart';
import 'package:messenger_backend/controllers/chat_controller.dart';
import 'package:messenger_backend/middlewares/auth_middleware.dart';

class ChatRoutes extends RouteGroup {
  @override
  String get prefix => '/chat';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final chat = app.controller(ChatController.new);

    /// @summary Find a user by phone number
    /// @auth bearer
    chat.get('/users/lookup', (c) => c.findUser()).useMiddleware(AuthMiddleware());

    /// @summary Message history with a user
    /// @auth bearer
    chat.get('/messages/:userId', (c) => c.history()).useMiddleware(AuthMiddleware());

    /// @summary Get a user by id
    /// @auth bearer
    chat.get('/peers/:id', (c) => c.getPeer()).useMiddleware(AuthMiddleware());
  }
}
