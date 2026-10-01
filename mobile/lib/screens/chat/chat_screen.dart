import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/users_provider.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/pinned_message_bar.dart';

class ChatScreen extends StatefulWidget {
  final UserModel partner;
  const ChatScreen({super.key, required this.partner});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _record = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollCtrl.addListener(_onScroll);
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    chat.loadMessages(widget.partner.id, refresh: true).then((_) {
      // Mark messages as seen
      chat.markMessagesSeen(widget.partner.id, auth.user!.id);
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ChatProvider>().loadMore(widget.partner.id);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _record.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await context.read<ChatProvider>().sendText(text, widget.partner.id);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null || !mounted) return;
    await context
        .read<ChatProvider>()
        .sendFile(File(xfile.path), widget.partner.id);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.single.path == null || !mounted) return;
    await context
        .read<ChatProvider>()
        .sendFile(File(result.files.single.path!), widget.partner.id);
  }

  Future<void> _startRecording() async {
    final hasPermission = await _record.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _record.start(
      RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _recordSeconds++));
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _record.stop();
    setState(() => _isRecording = false);
    if (path != null && mounted) {
      await context
          .read<ChatProvider>()
          .sendFile(File(path), widget.partner.id, isVoice: true);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.partner.name}!',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final users = context.watch<UsersProvider>();
    final isOnline = users.isOnline(widget.partner.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: UserAvatar(
                      url: widget.partner.profilePic,
                      name: widget.partner.name,
                      radius: 20),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partner.name,
                    style: const TextStyle(
                        color: Color(0xFF2C2C2C),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    chat.partnerIsTyping
                        ? 'typing...'
                        : isOnline
                            ? 'Online'
                            : 'Offline',
                    style: TextStyle(
                      color: chat.partnerIsTyping
                          ? const Color(0xFFFF7A00)
                          : const Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2C2C2C)),
            color: Colors.white,
            onSelected: (v) async {
              if (v == 'clear') {
                final confirm = await _confirmDialog(
                    context, 'Clear Chat', 'Clear all messages for you?');
                if (confirm == true) {
                  await chat.clearChat(widget.partner.id);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'search',
                child: Text('Search', style: TextStyle(color: Color(0xFF2C2C2C))),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat', style: TextStyle(color: Color(0xFF2C2C2C))),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned message bar
          if (chat.pinnedMessage != null)
            Container(
              color: const Color(0xFFFFF7ED),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFFFEDD5))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, color: Color(0xFFFF7A00), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pinned Message',
                            style: TextStyle(
                                color: Color(0xFFFF7A00),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(
                          chat.pinnedMessage!.text.isNotEmpty
                              ? chat.pinnedMessage!.text
                              : '[Attachment]',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF2C2C2C), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black38, size: 16),
                    onPressed: () => chat.unpinMessage(chat.pinnedMessage!.id),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: chat.loading && chat.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
                : chat.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: chat.messages.length +
                            (chat.hasMore ? 1 : 0) +
                            (chat.partnerIsTyping ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (chat.partnerIsTyping && i == 0) {
                            return _TypingIndicator();
                          }
                          final msgIndex =
                              chat.partnerIsTyping ? i - 1 : i;
                          if (msgIndex == chat.messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFFF7A00)),
                                ),
                              ),
                            );
                          }
                          final msg = chat.messages[msgIndex];

                          // Apply new design for text messages
                          if (msg.text.isNotEmpty) {
                            return _NewMessageBubble(
                              message: msg,
                              isMe: msg.senderId == auth.user!.id,
                              onReply: () => chat.setReplyingTo(msg),
                              onDelete: (everywhere) => chat.deleteMessage(
                                  msg.id,
                                  deleteForEveryone: everywhere),
                              onReact: (emoji) =>
                                  chat.reactToMessage(msg.id, emoji),
                              onPin: () => chat.pinMessage(msg.id),
                              onUnpin: () => chat.unpinMessage(msg.id),
                              isPinned: chat.pinnedMessage?.id == msg.id,
                            );
                          }

                          // Fallback for rich attachments
                          return MessageBubble(
                            message: msg,
                            isMe: msg.senderId == auth.user!.id,
                            currentUserId: auth.user!.id,
                            onReply: () => chat.setReplyingTo(msg),
                            onDelete: (everywhere) =>
                                chat.deleteMessage(msg.id,
                                    deleteForEveryone: everywhere),
                            onReact: (emoji) =>
                                chat.reactToMessage(msg.id, emoji),
                            onPin: () => chat.pinMessage(msg.id),
                            onUnpin: () => chat.unpinMessage(msg.id),
                            isPinned: chat.pinnedMessage?.id == msg.id,
                          );
                        },
                      ),
          ),

          // Reply preview
          if (chat.replyingTo != null)
            _ReplyPreview(
              message: chat.replyingTo!,
              onCancel: () => chat.setReplyingTo(null),
            ),

          // Input bar
          _InputBar(
            controller: _textCtrl,
            isRecording: _isRecording,
            recordSeconds: _recordSeconds,
            onSend: _sendText,
            onPickImage: _pickImage,
            onPickFile: _pickFile,
            onStartRecord: _startRecording,
            onStopRecord: _stopRecording,
            onChanged: (v) => chat.onInputChanged(
                v, auth.user!.id, widget.partner.id),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Color(0xFF2C2C2C))),
        content: Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Color(0xFFFF7A00))),
          ),
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final val =
                    math.sin((_ctrl.value * 2 * math.pi) - (index * 1.0));
                final dy = val > 0 ? -val * 4 : 0.0;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A00),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── New Message Bubble ────────────────────────────────────────────────────────
class _NewMessageBubble extends StatelessWidget {
  final dynamic message; 
  final bool isMe;
  final VoidCallback onReply;
  final Function(bool) onDelete;
  final Function(String) onReact;
  final VoidCallback onPin;
  final VoidCallback onUnpin;
  final bool isPinned;

  const _NewMessageBubble({
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onDelete,
    required this.onReact,
    required this.onPin,
    required this.onUnpin,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? const Color(0xFFFF7A00) : Colors.white;
    final textColor = isMe ? Colors.white : const Color(0xFF2C2C2C);
    final border = isMe ? null : Border.all(color: const Color(0xFFF3F4F6));
    
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    String timeStr = '';
    try {
      if (message.createdAt != null) {
        final d = message.createdAt as DateTime;
        timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    bool hasReply = false;
    try {
      hasReply = message.replyTo != null;
    } catch (_) {}

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.reply, color: Color(0xFF2C2C2C)),
                  title: const Text('Reply', style: TextStyle(color: Color(0xFF2C2C2C))),
                  onTap: () { Navigator.pop(context); onReply(); },
                ),
                ListTile(
                  leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Color(0xFF2C2C2C)),
                  title: Text(isPinned ? 'Unpin' : 'Pin', style: const TextStyle(color: Color(0xFF2C2C2C))),
                  onTap: () { Navigator.pop(context); isPinned ? onUnpin() : onPin(); },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () { Navigator.pop(context); onDelete(true); },
                ),
              ],
            ),
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasReply) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.white.withOpacity(0.4) : const Color(0xFFFF7A00),
                        width: 4,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Replied message', 
                    style: TextStyle(
                      color: isMe ? Colors.white70 : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              Text(
                message.text ?? '',
                style: TextStyle(color: textColor, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : const Color(0xFF9CA3AF),
                      fontSize: 9,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, color: Colors.white70, size: 12),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reply Preview ─────────────────────────────────────────────────────────────
class _ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onCancel;

  const _ReplyPreview({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            color: const Color(0xFFFF7A00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.text.isNotEmpty ? message.text : '[Attachment]',
              style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black38, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;
  final int recordSeconds;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final ValueChanged<String> onChanged;

  const _InputBar({
    required this.controller,
    required this.isRecording,
    required this.recordSeconds,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onChanged,
  });

  String get _formatTime {
    final m = (recordSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isRecording) ...[
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.black54),
                onPressed: () {}, 
              ),
              IconButton(
                icon: const Icon(Icons.image_outlined, color: Colors.black54),
                onPressed: onPickImage,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.black54),
                onPressed: onPickFile,
              ),
            ],
            Expanded(
              child: isRecording
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Recording $_formatTime',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: controller,
                      style: const TextStyle(color: Color(0xFF2C2C2C)),
                      maxLines: 4,
                      minLines: 1,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: const BorderSide(color: Color(0xFFFF7A00)),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, __) {
                if (val.text.isNotEmpty) {
                  return _circleBtn(
                    icon: Icons.send_rounded,
                    color: const Color(0xFFFF7A00),
                    onTap: onSend,
                  );
                }
                return GestureDetector(
                  onLongPressStart: (_) => onStartRecord(),
                  onLongPressEnd: (_) => onStopRecord(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isRecording
                          ? Colors.redAccent
                          : const Color(0xFFFF7A00),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
