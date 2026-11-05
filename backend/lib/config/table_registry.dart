import 'dart:isolate';
import 'package:flint_dart/flint_dart.dart';
import '../models/user_model.dart';
import '../models/verification_code_model.dart';
import '../models/message_model.dart';

void main(List<String> args, SendPort sendPort) {
  registerTableRegistry([
    User().table,
    VerificationCode().table,
    Message().table,
  ], null, sendPort);
}
