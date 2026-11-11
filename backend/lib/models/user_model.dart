import 'package:flint_dart/flint_dart.dart';

class User extends Model<User> {
  User() : super(() => User());

  String get phone => getAttribute('phone');
  String? get name => getAttribute('name');
  DateTime? get createdAt => getAttribute('created_at');

  @override
  Table get table => Table(
        name: 'users',
        columns: [
          Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true, isAutoIncrement: true),
          Column(name: 'phone', type: ColumnType.string, length: 20, isUnique: true),
          Column(name: 'name', type: ColumnType.string, length: 50, isNullable: true),
          Column(name: 'created_at', type: ColumnType.datetime, isNullable: true),
        ],
      );
}
