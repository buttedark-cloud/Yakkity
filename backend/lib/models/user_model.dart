import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/schema.dart'; // <-- Импорт схемы

class User extends Model<User> {
  User() : super(() => User());

  String get phone => getAttribute('phone');
  String? get profilePicUrl => getAttribute('profile_pic_url');
  DateTime? get createdAt => getAttribute('created_at');

  @override
  Table get table => Table(
        name: 'users',
        columns: [
          Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true, isAutoIncrement: true),
          Column(name: 'phone', type: ColumnType.string, length: 20, isUnique: true),
          Column(name: 'created_at', type: ColumnType.datetime, isNullable: true),
          Column(name: 'profile_pic_url', type: ColumnType.string, isNullable: true),
        ],
      );
}
