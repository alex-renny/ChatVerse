import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';

typedef DeleteCallback = void Function(bool deleteForEveryone);
typedef ReactCallback = void Function(String emoji);

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String currentUserId;
  final VoidCallback onReply;
  final DeleteCallback onDelete;
  final ReactCallback onReact;
  final VoidCallback onPin;
  final VoidCallback onUnpin;
  final bool isPinned;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.onReact,
    required this.onPin,
    required this.onUnpin,
    this.isPinned = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showEmoji = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMe = widget.isMe;

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Reply preview
            if (msg.replyTo != null) _replyPreview(msg.replyTo!),

            // Bubble
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.72),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF5B21B6)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        if (msg.image.isNotEmpty) _imageContent(msg.image),

                        // Attachment
                        if (msg.attachment != null)
                          _attachmentContent(msg.attachment!),

                        // Text
                        if (msg.text.isNotEmpty)
                          Text(
                            msg.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),

                        // Timestamp + status
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm')
                                  .format(msg.createdAt.toLocal()),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                msg.seen
                                    ? Icons.done_all
                                    : msg.delivered
                                        ? Icons.done_all
                                        : Icons.done,
                                size: 12,
                                color: msg.seen
                                    ? Colors.blueAccent
                                    : Colors.white38,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Reactions
            if (msg.reactions.isNotEmpty) _reactionRow(msg),

            // Emoji picker
            if (_showEmoji)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (_, e) {
                    widget.onReact(e.emoji);
                    setState(() => _showEmoji = false);
                  },
                  config: const Config(
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: Color(0xFF0F0F23),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _replyPreview(MessageModel reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111124),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
            left: BorderSide(color: Color(0xFF7C3AED), width: 3)),
      ),
      child: Text(
        reply.text.isNotEmpty ? reply.text : '[Attachment]',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _imageContent(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: 200,
          placeholder: (_, __) => Container(
            width: 200,
            height: 150,
            color: Colors.white12,
            child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 200,
            height: 100,
            color: Colors.white12,
            child: const Icon(Icons.broken_image, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget _attachmentContent(AttachmentModel att) {
    if (att.isImage) return _imageContent(att.url);
    if (att.isVoice) return _voiceContent(att);

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(att.url)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              att.isPdf
                  ? Icons.picture_as_pdf
                  : att.isVideo
                      ? Icons.videocam
                      : Icons.insert_drive_file,
              color: const Color(0xFF7C3AED),
              size: 28,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                att.name,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceContent(AttachmentModel att) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(att.url)),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        const Text('Voice message',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _reactionRow(MessageModel msg) {
    final grouped = <String, int>{};
    for (final r in msg.reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
      child: Wrap(
        spacing: 4,
        children: grouped.entries.map((e) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${e.key} ${e.value}',
                style: const TextStyle(fontSize: 11)),
          );
        }).toList(),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _optionTile(Icons.reply, 'Reply', () {
              Navigator.pop(context);
              widget.onReply();
            }),
            _optionTile(Icons.emoji_emotions_outlined, 'React', () {
              Navigator.pop(context);
              setState(() => _showEmoji = true);
            }),
            if (widget.isPinned)
              _optionTile(Icons.push_pin_outlined, 'Unpin', () {
                Navigator.pop(context);
                widget.onUnpin();
              })
            else
              _optionTile(Icons.push_pin, 'Pin Message', () {
                Navigator.pop(context);
                widget.onPin();
              }),
            if (widget.isMe)
              _optionTile(Icons.delete_forever, 'Delete for Everyone',
                  () {
                Navigator.pop(context);
                widget.onDelete(true);
              }, color: Colors.redAccent),
            _optionTile(Icons.delete_outline, 'Delete for Me', () {
              Navigator.pop(context);
              widget.onDelete(false);
            }, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading:
          Icon(icon, color: color ?? const Color(0xFF7C3AED), size: 22),
      title: Text(label,
          style: TextStyle(color: color ?? Colors.white70, fontSize: 15)),
      onTap: onTap,
    );
  }
}
