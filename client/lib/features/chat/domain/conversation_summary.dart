import 'package:equatable/equatable.dart';
import 'package:yakkity/features/chat/domain/chat_message.dart';

/// Одна строка в списке чатов: с кем и какое сообщение последнее
class ConversationSummary extends Equatable {
  const ConversationSummary({required this.peerId, required this.last, this.incoming = const []});

  final int peerId;
  final ChatMessage last;

  /// Время (в мс) всех входящих сообщений от этого собеседника
  final List<int> incoming;

  /// Сколько сообщений пришло позже отметки «прочитано до»
  int unread(int lastReadMs) => incoming.where((t) => t > lastReadMs).length;

  @override
  List<Object?> get props => [peerId, last, incoming];
}
