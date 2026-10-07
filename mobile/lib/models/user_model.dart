import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profilePic;
  final String bio;
  final String status;
  final DateTime? lastSeen;
  final bool isOnline;
  final bool isPinned;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final int unreadCount;
  final bool requiresChatLock;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic = '',
    this.bio = '',
    this.status = 'Available',
    this.lastSeen,
    this.isOnline = false,
    this.isPinned = false,
    this.lastMessageAt,
    this.lastMessagePreview = '',
    this.unreadCount = 0,
    this.requiresChatLock = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePic: json['profilePic']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Available',
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      isOnline: json['isOnline'] == true,
      isPinned: json['isPinned'] == true,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      requiresChatLock: json['requiresChatLock'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'profilePic': profilePic,
        'bio': bio,
        'status': status,
        'lastSeen': lastSeen?.toIso8601String(),
        'isOnline': isOnline,
        'isPinned': isPinned,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'lastMessagePreview': lastMessagePreview,
        'unreadCount': unreadCount,
        'requiresChatLock': requiresChatLock,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePic,
    String? bio,
    String? status,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isPinned,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
    bool? requiresChatLock,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isPinned: isPinned ?? this.isPinned,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      requiresChatLock: requiresChatLock ?? this.requiresChatLock,
    );
  }

  static UserModel fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}
