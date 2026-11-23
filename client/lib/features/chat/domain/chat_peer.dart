import 'package:equatable/equatable.dart';

/// Собеседник: у сообщений есть только id, а человеку нужны имя и номер
class ChatPeer extends Equatable {
  const ChatPeer({
    required this.id,
    required this.phone,
    this.name,
    this.status,
    this.avatarAsset,
  });

  final int id;
  final String phone;
  final String? name;
  final String? status;

  /// Фото из assets. Есть только у демо-людей и хранится только на устройстве.
  final String? avatarAsset;

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return phone.isNotEmpty ? phone : 'Пользователь $id';
  }

  bool get hasStatus => status != null && status!.trim().isNotEmpty;

  factory ChatPeer.fromJson(Map<String, dynamic> json) => ChatPeer(
        id: json['id'] as int,
        phone: json['phone'] as String,
        name: json['name'] as String?,
        status: json['status'] as String?,
      );

  factory ChatPeer.fromMap(Map<String, Object?> map) => ChatPeer(
        id: map['id'] as int,
        phone: map['phone'] as String,
        name: map['name'] as String?,
        status: map['status'] as String?,
        avatarAsset: map['avatarAsset'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'phone': phone,
        'name': name,
        'status': status,
        'avatarAsset': avatarAsset,
      };

  @override
  List<Object?> get props => [id, phone, name, status, avatarAsset];
}
