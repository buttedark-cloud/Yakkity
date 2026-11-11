import 'package:equatable/equatable.dart';
import 'package:yakkity/core/network/chat_socket.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';

class ChatState extends Equatable {
  const ChatState({this.messages = const [], this.connection = SocketStatus.disconnected, this.loadingHistory = true});

  final List<ChatMessage> messages;
  final SocketStatus connection;
  final bool loadingHistory;

  ChatState copyWith({List<ChatMessage>? messages, SocketStatus? connection, bool? loadingHistory}) => ChatState(
    messages: messages ?? this.messages,
    connection: connection ?? this.connection,
    loadingHistory: loadingHistory ?? this.loadingHistory,
  );

  @override
  List<Object?> get props => [messages, connection, loadingHistory];
}
