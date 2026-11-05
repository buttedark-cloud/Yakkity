import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/schema.dart'; // <-- Импорт схемы

class VerificationCode extends Model<VerificationCode> {
  VerificationCode() : super(() => VerificationCode());

  String get phone => getAttribute('phone');
  String get code => getAttribute('code');
  DateTime get expiresAt => getAttribute('expires_at');

  @override
  Table get table => Table(
        name: 'verification_codes',
        columns: [
          Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true, isAutoIncrement: true),
          Column(name: 'phone', type: ColumnType.string, length: 20, isUnique: true),
          Column(name: 'code', type: ColumnType.string, length: 6),
          Column(name: 'expires_at', type: ColumnType.datetime),
          Column(name: 'created_at', type: ColumnType.datetime, isNullable: true),
        ],
      );
}
