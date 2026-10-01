import 'dart:async';
import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final users = context.watch<UsersProvider>();
    final isOnline = users.isOnline(widget.partner.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F23),
        leadingWidth: 30,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            UserAvatar(
                url: widget.partner.profilePic,
                name: widget.partner.name,
                radius: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partner.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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
                        ? const Color(0xFF7C3AED)
                        : isOnline
                            ? Colors.greenAccent
                            : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1A1A2E),
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
                value: 'clear',
                child: Text('Clear Chat',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned message bar
          if (chat.pinnedMessage != null)
            PinnedMessageBar(
              message: chat.pinnedMessage!,
              currentUserId: auth.user!.id,
              onUnpin: () =>
                  chat.unpinMessage(chat.pinnedMessage!.id),
            ),

          // Messages list
          Expanded(
            child: chat.loading && chat.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: chat.messages.length +
                        (chat.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == chat.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF7C3AED)),
                            ),
                          ),
                        );
                      }
                      final msg = chat.messages[i];
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
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
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
      color: const Color(0xFF141428),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.text.isNotEmpty ? message.text : '[Attachment]',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
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
      color: const Color(0xFF0F0F23),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isRecording) ...[
              IconButton(
                icon: const Icon(Icons.image_outlined, color: Colors.white54),
                onPressed: onPickImage,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.white54),
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
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Recording $_formatTime',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      minLines: 1,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle:
                            const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 4),

            // Mic / send button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, __) {
                if (val.text.isNotEmpty) {
                  return _circleBtn(
                    icon: Icons.send_rounded,
                    color: const Color(0xFF7C3AED),
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
                          : const Color(0xFF7C3AED),
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
