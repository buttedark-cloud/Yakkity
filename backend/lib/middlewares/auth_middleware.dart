import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/auth.dart';

/// Пропускает запрос дальше только если в заголовке
/// Authorization: Bearer <token> лежит настоящий JWT.
class AuthMiddleware extends Middleware {
  @override
  Handler handle(Handler next) {
    return (Context ctx) async {
      final res = ctx.res;
      if (res == null) return null;

      final token = ctx.req.bearerToken;
      final payload = token == null ? null : Auth.verifyToken(token);

      if (payload == null) {
        return res.status(401).json({
          "status": "error",
          "message": "Authentication required.",
        });
      }
      return await next(ctx);
    };
  }
}
