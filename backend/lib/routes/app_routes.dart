import 'package:flint_dart/flint_dart.dart';
import 'auth_routes.dart';
import 'chat_routes.dart';

/// Main route group for the entire app
class AppRoutes extends RouteGroup {
  @override
  String get prefix => '';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    // Проверка, что сервер жив
    app.get('/', (Context ctx) async {
      return ctx.res?.json({'status': 'ok', 'service': 'messenger-backend'});
    });

    app.routes(AuthRoutes());
    app.routes(ChatRoutes());
  }
}
