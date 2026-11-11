import 'package:equatable/equatable.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';

/// Одна строка в списке чатов: с кем и какое сообщение последнее
class ConversationSummary extends Equatable {
  const ConversationSummary({required this.peerId, required this.last});

  final int peerId;
  final ChatMessage last;

  @override
  List<Object?> get props => [peerId, last];
}
