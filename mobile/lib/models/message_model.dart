class ReactionModel {
  final String userId;
  final String emoji;

  const ReactionModel({required this.userId, required this.emoji});

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ReactionModel(
      userId: (user is Map ? user['_id'] : user)?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'user': userId, 'emoji': emoji};
}

class AttachmentModel {
  final String url;
  final String name;
  final String mimeType;
  final int size;
  final bool isVoice;
  final String resourceType;

  const AttachmentModel({
    required this.url,
    required this.name,
    required this.mimeType,
    required this.size,
    this.isVoice = false,
    this.resourceType = 'raw',
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      url: json['url']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      isVoice: json['isVoice'] == true,
      resourceType: json['resourceType']?.toString() ?? 'raw',
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'mimeType': mimeType,
        'size': size,
        'isVoice': isVoice,
        'resourceType': resourceType,
      };

  bool get isImage {
    if (mimeType.toLowerCase().startsWith('image/')) return true;
    if (url.toLowerCase().contains('/image/upload/')) return true;
    final nameOrUrl = '$name $url'.toLowerCase().split('?').first;
    return RegExp(r'\.(png|jpe?g|gif|webp|bmp|heic)(\s|$)').hasMatch(nameOrUrl);
  }
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isPdf => mimeType == 'application/pdf';
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String image;
  final AttachmentModel? attachment;
  final MessageModel? replyTo;
  final List<ReactionModel> reactions;
  final bool delivered;
  final bool seen;
  final bool pinned;
  final String? pinnedBy;
  final DateTime? pinnedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSending;

  String get previewText {
    if (text.trim().isNotEmpty) return text.trim();
    if (image.isNotEmpty || attachment?.isImage == true) return '📷 Photo';
    if (attachment?.isVoice == true) return '🎙 Voice message';
    if (attachment?.isVideo == true) return '🎬 Video';
    if (attachment?.isAudio == true) return '🎵 Audio';
    if (attachment?.isPdf == true) return '📄 PDF';
    if (attachment != null) {
      final name = attachment!.name.trim();
      return name.isEmpty ? '📎 Attachment' : '📎 $name';
    }
    return 'Message unavailable';
  }

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.image = '',
    this.attachment,
    this.replyTo,
    this.reactions = const [],
    this.delivered = false,
    this.seen = false,
    this.pinned = false,
    this.pinnedBy,
    this.pinnedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSending = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final receiver = json['receiver'];

    String senderId =
        (sender is Map ? sender['_id'] : sender)?.toString() ?? '';
    String receiverId =
        (receiver is Map ? receiver['_id'] : receiver)?.toString() ?? '';

    final attachmentJson = json['attachment'] is Map
        ? Map<String, dynamic>.from(json['attachment'] as Map)
        : (json['file'] is String && (json['file'] as String).isNotEmpty
            ? <String, dynamic>{
                'url': json['file'],
                'name': json['fileName'] ?? json['file'],
                'mimeType': json['mimeType'] ?? '',
              }
            : null);
    return MessageModel(
      id: json['_id']?.toString() ?? '',
      senderId: senderId,
      receiverId: receiverId,
      text: json['text']?.toString() ?? '',
      image: (json['image'] ?? '').toString(),
      attachment: attachmentJson != null
          ? AttachmentModel.fromJson(attachmentJson)
          : null,
      replyTo: json['replyTo'] != null && json['replyTo'] is Map
          ? MessageModel.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((r) => ReactionModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      delivered: json['delivered'] == true,
      seen: json['seen'] == true,
      pinned: json['pinned'] == true,
      pinnedBy: json['pinnedBy']?.toString(),
      pinnedAt: json['pinnedAt'] != null
          ? DateTime.tryParse(json['pinnedAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      isSending: false,
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? image,
    AttachmentModel? attachment,
    MessageModel? replyTo,
    List<ReactionModel>? reactions,
    bool? delivered,
    bool? seen,
    bool? pinned,
    String? pinnedBy,
    DateTime? pinnedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSending,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      image: image ?? this.image,
      attachment: attachment ?? this.attachment,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      delivered: delivered ?? this.delivered,
      seen: seen ?? this.seen,
      pinned: pinned ?? this.pinned,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSending: isSending ?? this.isSending,
    );
  }
}
