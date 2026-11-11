import 'package:equatable/equatable.dart';

/// Собеседник: у сообщений есть только id, а человеку нужны имя и номер
class ChatPeer extends Equatable {
  const ChatPeer({required this.id, required this.phone, this.name});

  final int id;
  final String phone;
  final String? name;

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return phone.isNotEmpty ? phone : 'Пользователь $id';
  }

  /// Первая буква для аватарки
  String get initial {
    final s = displayName.replaceAll('+', '');
    return s.isEmpty ? '?' : String.fromCharCode(s.runes.first).toUpperCase();
  }

  factory ChatPeer.fromJson(Map<String, dynamic> json) =>
      ChatPeer(id: json['id'] as int, phone: json['phone'] as String, name: json['name'] as String?);

  factory ChatPeer.fromMap(Map<String, Object?> map) =>
      ChatPeer(id: map['id'] as int, phone: map['phone'] as String, name: map['name'] as String?);

  Map<String, Object?> toMap() => {'id': id, 'phone': phone, 'name': name};

  @override
  List<Object?> get props => [id, phone, name];
}
