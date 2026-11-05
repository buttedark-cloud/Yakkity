import 'dart:async';

class SessionEvents {
  final _controller = StreamController<void>.broadcast();
  Stream<void> get onExpired => _controller.stream;
  void expired() => _controller.add(null);
}
