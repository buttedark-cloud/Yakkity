import 'package:flint_dart/flint_dart.dart';
import 'package:messenger_backend/controllers/auth_controller.dart';

/// Auth API routes
class AuthRoutes extends RouteGroup {
  @override
  String get prefix => '/auth';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = app.controller(AuthController.new);

    /// @summary Send verification code to a phone number
    /// @response 200 Code sent
    /// @response 422 Invalid phone number
    /// @body {"phone": "+996700123456"}
    auth.post('/send-code', (c) => c.sendCode());

    /// @summary Verify the code and get a JWT token
    /// @response 200 Signed in
    /// @response 401 Invalid or expired code
    /// @body {"phone": "+996700123456", "code": "123456"}
    auth.post('/verify', (c) => c.verify());

    /// @summary Current user (requires Bearer token)
    /// @auth bearer
    /// @response 200 Current user
    /// @response 401 Unauthorized
    auth.get('/me', (c) => c.me());
  }
}
