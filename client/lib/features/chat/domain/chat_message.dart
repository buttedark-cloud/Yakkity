import 'dart:math';

import 'package:equatable/equatable.dart';

enum MessageStatus { pending, sent, failed }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.clientId,
    this.serverId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.status,
  });

  /// Ключ записи в локальной базе. Придумывается на устройстве.
  final String clientId;

  /// id с сервера. Пока сообщение не доставлено, его нет.
  final int? serverId;
  final int senderId;
  final int receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  /// Новое сообщение, которое пользователь только что написал
  factory ChatMessage.pending({required int senderId, required int receiverId, required String text}) => ChatMessage(
    clientId: '$senderId-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}',
    senderId: senderId,
    receiverId: receiverId,
    text: text,
    createdAt: DateTime.now().toUtc(),
    status: MessageStatus.pending,
  );

  /// Сообщение в том виде, в котором его присылает сервер
  factory ChatMessage.fromServerJson(Map<String, dynamic> json) => ChatMessage(
    clientId: (json['clientId'] as String?) ?? 'srv-${json['id']}',
    serverId: json['id'] as int,
    senderId: json['sender_id'] as int,
    receiverId: json['receiver_id'] as int,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    status: MessageStatus.sent,
  );

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
    clientId: map['clientId'] as String,
    serverId: map['serverId'] as int?,
    senderId: map['senderId'] as int,
    receiverId: map['receiverId'] as int,
    text: map['text'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int, isUtc: true),
    status: MessageStatus.values.byName(map['status'] as String),
  );

  Map<String, Object?> toMap() => {
    'clientId': clientId,
    'serverId': serverId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'status': status.name,
  };

  ChatMessage copyWith({String? clientId, int? serverId, DateTime? createdAt, MessageStatus? status}) => ChatMessage(
    clientId: clientId ?? this.clientId,
    serverId: serverId ?? this.serverId,
    senderId: senderId,
    receiverId: receiverId,
    text: text,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [clientId, serverId, senderId, receiverId, text, createdAt, status];
}
