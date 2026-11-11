import 'package:flint_dart/flint_dart.dart';

class Message extends Model<Message> {
  Message() : super(() => Message());

  int get senderId => getAttribute('sender_id');
  int get receiverId => getAttribute('receiver_id');
  String get text => getAttribute('text');
  String? get clientId => getAttribute('client_id');
  DateTime? get createdAt => getAttribute('created_at');

  @override
  Table get table => Table(
        name: 'messages',
        columns: [
          Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true, isAutoIncrement: true),
          Column(name: 'sender_id', type: ColumnType.integer),
          Column(name: 'receiver_id', type: ColumnType.integer),
          Column(name: 'text', type: ColumnType.text),
          // Уникальный id сообщения с устройства: защита от дублей при повторной отправке
          Column(name: 'client_id', type: ColumnType.string, length: 64, isNullable: true, isUnique: true),
          Column(name: 'created_at', type: ColumnType.datetime, isNullable: true),
        ],
      );
}
