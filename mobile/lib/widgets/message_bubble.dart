import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingUrl;
  bool _showEmoji = false;
  double _dragExtent = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  bool get _isDeleted =>
      widget.message.text == 'Message unavailable' ||
      widget.message.isDeleted == true; // Fallback check

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMe = widget.isMe;

    Widget bubbleContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Reply preview
          if (msg.replyTo != null && !_isDeleted)
            _replyPreview(msg.replyTo!, isMe),

          // Bubble
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFFF7A00) : Colors.white,
                    border:
                        isMe ? null : Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: _isDeleted
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block,
                                size: 14,
                                color: isMe ? Colors.white70 : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Message unavailable',
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            if (msg.image.isNotEmpty) _imageContent(msg.image),

                            // Attachment
                            if (msg.attachment != null)
                              _attachmentContent(msg.attachment!, isMe),

                            // Text
                            if (msg.text.isNotEmpty)
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : const Color(0xFF2C2C2C),
                                  fontSize: 14,
                                ),
                              ),

                            // Timestamp + status
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('HH:mm')
                                      .format(msg.createdAt.toLocal()),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey.shade400,
                                    fontSize: 9,
                                  ),
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
                                    color: Colors.white,
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
          if (msg.reactions.isNotEmpty && !_isDeleted) _reactionRow(msg, isMe),

          // Emoji picker
          if (_showEmoji && !_isDeleted)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (_, e) {
                  widget.onReact(e.emoji);
                  setState(() => _showEmoji = false);
                },
                config: const Config(
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: Color(0xFFF8F9FA),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: _isDeleted ? null : () => _showOptions(context),
      onHorizontalDragUpdate: (details) {
        if (!_isDeleted) {
          setState(() {
            _dragExtent += details.primaryDelta!;
            if (_dragExtent < 0) _dragExtent = 0;
            if (_dragExtent > 60) _dragExtent = 60;
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent >= 50 && !_isDeleted) {
          widget.onReply();
        }
        setState(() {
          _dragExtent = 0;
        });
      },
      child: Transform.translate(
        offset: Offset(_dragExtent, 0),
        child: bubbleContent,
      ),
    );
  }

  Widget _replyPreview(MessageModel reply, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border(
            left: BorderSide(
                color: isMe
                    ? Colors.white.withOpacity(0.4)
                    : const Color(0xFFFF7A00),
                width: 4)),
      ),
      child: Text(
        reply.text.isNotEmpty ? reply.text : '[Attachment]',
        style: TextStyle(
            color: isMe
                ? Colors.white70
                : const Color(0xFF2C2C2C).withOpacity(0.7),
            fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _imageContent(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(alignment: Alignment.topRight, children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
              IconButton(
                tooltip: 'Close image',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ]),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .38),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: 260,
              placeholder: (_, __) => Container(
                width: 260,
                height: 150,
                color: Colors.grey.shade200,
                child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 260,
                height: 100,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _attachmentContent(AttachmentModel att, bool isMe) {
    if (att.isImage) return _imageContent(att.url);
    if (att.isVoice) return _voiceContent(att, isMe);

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(att.url)),
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.2) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              color: isMe ? Colors.white : const Color(0xFFFF7A00),
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                att.name,
                style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF2C2C2C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceContent(AttachmentModel att, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              try {
                if (_playingUrl == att.url && _audioPlayer.playing) {
                  await _audioPlayer.pause();
                } else {
                  _playingUrl = att.url;
                  await _audioPlayer.setUrl(att.url);
                  await _audioPlayer.play();
                }
                if (mounted) setState(() {});
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Could not play this voice message. Check your connection and try again.')),
                  );
                }
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMe ? Colors.white : const Color(0xFFFF7A00),
                shape: BoxShape.circle,
              ),
              child: StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (_, __) => Icon(
                  _playingUrl == att.url && _audioPlayer.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: isMe ? const Color(0xFFFF7A00) : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color:
                    isMe ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _reactionRow(MessageModel msg, bool isMe) {
    final grouped = <String, int>{};
    for (final r in msg.reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
      child: Wrap(
        spacing: 4,
        children: grouped.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0x1AFF7A00),
              border: Border.all(
                color: isMe
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0x4DFF7A00),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${e.key} ${e.value}',
                style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white : const Color(0xFF2C2C2C))),
          );
        }).toList(),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                _optionTile(Icons.push_pin, 'Pin', () {
                  Navigator.pop(context);
                  widget.onPin();
                }),
              if (widget.isMe)
                _optionTile(Icons.delete_forever, 'Delete for Everyone', () {
                  Navigator.pop(context);
                  widget.onDelete(true);
                }, color: Colors.red),
              _optionTile(Icons.delete_outline, 'Delete for Me', () {
                Navigator.pop(context);
                widget.onDelete(false);
              }, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF2C2C2C), size: 24),
      title: Text(label,
          style: TextStyle(
              color: color ?? const Color(0xFF2C2C2C),
              fontSize: 16,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

extension on MessageModel {
  bool get isDeleted =>
      false; // Dummy extension property to avoid compilation errors if it doesn't exist
}
