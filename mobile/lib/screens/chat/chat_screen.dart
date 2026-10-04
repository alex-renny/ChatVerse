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
import '../../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/password_prompt_dialog.dart';

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
  bool _isRecordingPaused = false;
  bool _showEmojiPicker = false;
  String? _recordPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  bool _locked = false;
  bool _showSearch = false;
  String _searchQuery = '';
  String _background = '';
  static const _backgrounds = [
    'https://res.cloudinary.com/nbsbvhdj/image/upload/v1784960807/samples/landscapes/nature-mountains.jpg',
    'https://res.cloudinary.com/nbsbvhdj/image/upload/v1784960807/samples/landscapes/beach-boat.jpg',
    'https://res.cloudinary.com/nbsbvhdj/image/upload/v1784960807/samples/animals/cat.jpg',
    'https://res.cloudinary.com/nbsbvhdj/image/upload/v1784960807/samples/food/dessert.jpg',
    'https://res.cloudinary.com/nbsbvhdj/image/upload/v1784960807/samples/people/jazz.jpg',
    'https://res.cloudinary.com/nbsbvhdj/image/upload/v1784960807/samples/balloons.jpg',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollCtrl.addListener(_onScroll);
  }

  Future<void> _load() async {
    if (await ApiService.isChatPasswordEnabled(widget.partner.id)) {
      if (mounted) setState(() => _locked = true);
      return;
    }
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    _background = await ApiService.getChatBackground(widget.partner.id);
    await chat.loadMessages(widget.partner.id, refresh: true);
    if (chat.error == 'chat_password_required') {
      if (mounted) setState(() => _locked = true);
      return;
    }
    if (!mounted) return;
    setState(() => _locked = false);
    chat.markMessagesSeen(widget.partner.id, auth.user!.id);
  }

  Future<void> _unlockChat() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordPromptDialog(
        title: 'Private chat',
        hint: 'Enter chat password',
        confirmLabel: 'Unlock',
      ),
    );
    if (password == null) return;
    if (await ApiService.verifyChatPassword(widget.partner.id, password)) {
      await _loadMessages();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Incorrect password')));
    }
  }

  Future<void> _chooseBackground() async {
    final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
                child: SizedBox(
              height: 300,
              child: Column(children: [
                const ListTile(title: Text('Chat background')),
                Expanded(
                    child: GridView.count(crossAxisCount: 3, children: [
                  ..._backgrounds.map((url) => InkWell(
                      onTap: () => Navigator.pop(ctx, url),
                      child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.broken_image))))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: const Text('Remove')),
                ])),
              ]),
            )));
    if (selected != null &&
        await ApiService.saveChatBackground(widget.partner.id, selected) &&
        mounted) setState(() => _background = selected);
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
    final sent =
        await context.read<ChatProvider>().sendText(text, widget.partner.id);
    if (!sent && mounted) {
      if (_textCtrl.text.isEmpty) _textCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Message could not be sent. Check your connection and try again.')),
      );
    }
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
    if (_isRecording) return;
    final hasPermission = await _record.hasPermission();
    if (!hasPermission) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Microphone permission is required to record voice messages')),
        );
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _record.start(
      RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );
    setState(() {
      _isRecording = true;
      _isRecordingPaused = false;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isRecordingPaused) setState(() => _recordSeconds++);
    });
  }

  Future<void> _toggleRecordingPause() async {
    if (!_isRecording) return;
    if (_isRecordingPaused) {
      await _record.resume();
    } else {
      await _record.pause();
    }
    if (mounted) setState(() => _isRecordingPaused = !_isRecordingPaused);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final path = await _record.stop();
    if (mounted)
      setState(() {
        _isRecording = false;
        _isRecordingPaused = false;
      });
    if (path != null && mounted && await File(path).exists()) {
      await context
          .read<ChatProvider>()
          .sendFile(File(path), widget.partner.id, isVoice: true);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final path = await _record.stop();
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (mounted)
      setState(() {
        _isRecording = false;
        _isRecordingPaused = false;
      });
  }

  void _insertEmoji(String emoji) {
    final value = _textCtrl.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final text = value.text.replaceRange(start, end, emoji);
    _textCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
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
    final visibleMessages = _searchQuery.trim().isEmpty
        ? chat.messages
        : chat.messages
            .where((m) =>
                m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

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
              if (v == 'search') setState(() => _showSearch = !_showSearch);
              if (v == 'background') await _chooseBackground();
              if (v == 'pinChat')
                await users.togglePinnedChat(widget.partner.id);
              if (v == 'clear') {
                final confirm = await _confirmDialog(
                    context, 'Clear Chat', 'Clear all messages for you?');
                if (!mounted) return;
                if (confirm == true) {
                  await chat.clearChat(widget.partner.id);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'search',
                child:
                    Text('Search', style: TextStyle(color: Color(0xFF2C2C2C))),
              ),
              PopupMenuItem(
                value: 'pinChat',
                child: Text(users.sidebarUsers
                            .where((u) => u.id == widget.partner.id)
                            .firstOrNull
                            ?.isPinned ==
                        true
                    ? 'Unpin chat'
                    : 'Pin chat'),
              ),
              const PopupMenuItem(
                  value: 'background', child: Text('Change background')),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat',
                    style: TextStyle(color: Color(0xFF2C2C2C))),
              ),
            ],
          ),
        ],
      ),
      body: _locked
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline,
                  size: 48, color: Color(0xFFFF7A00)),
              const SizedBox(height: 12),
              const Text('This chat is password protected'),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _unlockChat, child: const Text('Unlock chat')),
            ]))
          : Stack(fit: StackFit.expand, children: [
              if (_background.isNotEmpty)
                Positioned.fill(
                    child: CachedNetworkImage(
                        imageUrl: _background,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink())),
              Column(
                children: [
                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search messages',
                            suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                      _showSearch = false;
                                      _searchQuery = '';
                                    })),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                  // Pinned message bar
                  if (chat.pinnedMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFFFEDD5))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.push_pin,
                              color: Color(0xFFFF7A00), size: 16),
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
                            icon: const Icon(Icons.close,
                                color: Colors.black38, size: 16),
                            onPressed: () =>
                                chat.unpinMessage(chat.pinnedMessage!.id),
                          ),
                        ],
                      ),
                    ),

                  // Messages list
                  Expanded(
                    child: chat.loading && chat.messages.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFF7A00)))
                        : visibleMessages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                itemCount: visibleMessages.length +
                                    (_searchQuery.isEmpty && chat.hasMore
                                        ? 1
                                        : 0) +
                                    (chat.partnerIsTyping ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (chat.partnerIsTyping && i == 0) {
                                    return _TypingIndicator();
                                  }
                                  final msgIndex =
                                      chat.partnerIsTyping ? i - 1 : i;
                                  if (msgIndex == visibleMessages.length) {
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
                                  final msg = visibleMessages[msgIndex];

                                  // Apply new design for text messages
                                  if (msg.text.isNotEmpty &&
                                      msg.image.isEmpty &&
                                      msg.attachment == null) {
                                    return _animateMessage(
                                        msg.id,
                                        _NewMessageBubble(
                                          message: msg,
                                          isMe: msg.senderId == auth.user!.id,
                                          onReply: () =>
                                              chat.setReplyingTo(msg),
                                          onDelete: (everywhere) =>
                                              chat.deleteMessage(msg.id,
                                                  deleteForEveryone:
                                                      everywhere),
                                          onReact: (emoji) => chat
                                              .reactToMessage(msg.id, emoji),
                                          onPin: () => chat.pinMessage(msg.id),
                                          onUnpin: () =>
                                              chat.unpinMessage(msg.id),
                                          isPinned:
                                              chat.pinnedMessage?.id == msg.id,
                                        ));
                                  }

                                  // Fallback for rich attachments
                                  return _animateMessage(
                                      msg.id,
                                      MessageBubble(
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
                                        onUnpin: () =>
                                            chat.unpinMessage(msg.id),
                                        isPinned:
                                            chat.pinnedMessage?.id == msg.id,
                                      ));
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
                    isRecordingPaused: _isRecordingPaused,
                    showEmojiPicker: _showEmojiPicker,
                    recordSeconds: _recordSeconds,
                    onSend: _sendText,
                    onPickImage: _pickImage,
                    onPickFile: _pickFile,
                    onStartRecord: _startRecording,
                    onStopRecord: _stopRecording,
                    onCancelRecord: _cancelRecording,
                    onTogglePause: _toggleRecordingPause,
                    onEmojiToggle: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                    },
                    onEmojiSelected: _insertEmoji,
                    onHideEmoji: () {
                      if (_showEmojiPicker)
                        setState(() => _showEmojiPicker = false);
                    },
                    onChanged: (v) => chat.onInputChanged(
                        v, auth.user!.id, widget.partner.id),
                  ),
                  if (chat.sending)
                    const LinearProgressIndicator(
                        minHeight: 2, color: Color(0xFFFF7A00)),
                ],
              ),
            ]),
    );
  }

  Widget _animateMessage(String id, Widget child) =>
      TweenAnimationBuilder<double>(
        key: ValueKey(id),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, (1 - value) * 10), child: child),
        ),
        child: child,
      );

  Future<bool?> _confirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Color(0xFF2C2C2C))),
        content:
            Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
  final MessageModel message;
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
      final d = message.createdAt;
      timeStr =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    final hasReply = message.replyTo != null;

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
                  title: const Text('Reply',
                      style: TextStyle(color: Color(0xFF2C2C2C))),
                  onTap: () {
                    Navigator.pop(context);
                    onReply();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_emotions_outlined,
                      color: Color(0xFF2C2C2C)),
                  title: const Text('React',
                      style: TextStyle(color: Color(0xFF2C2C2C))),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: ['❤️', '😂', '👍', '😮', '😢', '🙏']
                                    .map((emoji) => TextButton(
                                        onPressed: () {
                                          onReact(emoji);
                                          Navigator.pop(ctx);
                                        },
                                        child: Text(emoji,
                                            style:
                                                const TextStyle(fontSize: 26))))
                                    .toList())));
                  },
                ),
                ListTile(
                  leading: Icon(
                      isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                      color: Color(0xFF2C2C2C)),
                  title: Text(isPinned ? 'Unpin' : 'Pin',
                      style: const TextStyle(color: Color(0xFF2C2C2C))),
                  onTap: () {
                    Navigator.pop(context);
                    isPinned ? onUnpin() : onPin();
                  },
                ),
                if (isMe)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete for Everyone',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete(true);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete for Me',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete(false);
                  },
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
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasReply) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    border: Border(
                      left: BorderSide(
                        color: isMe
                            ? Colors.white.withOpacity(0.4)
                            : const Color(0xFFFF7A00),
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
                message.text,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                      spacing: 4,
                      children: _groupReactions(message.reactions)
                          .entries
                          .map((entry) => Text('${entry.key} ${entry.value}',
                              style: TextStyle(fontSize: 12, color: textColor)))
                          .toList()),
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
                    if (message.isSending)
                      const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white70))
                    else
                      const Icon(Icons.done_all,
                          color: Colors.white70, size: 12),
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

Map<String, int> _groupReactions(List<ReactionModel> reactions) {
  final grouped = <String, int>{};
  for (final reaction in reactions) {
    grouped[reaction.emoji] = (grouped[reaction.emoji] ?? 0) + 1;
  }
  return grouped;
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
  final bool isRecordingPaused;
  final bool showEmojiPicker;
  final int recordSeconds;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final VoidCallback onCancelRecord;
  final VoidCallback onTogglePause;
  final VoidCallback onEmojiToggle;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onHideEmoji;
  final ValueChanged<String> onChanged;

  const _InputBar({
    required this.controller,
    required this.isRecording,
    required this.isRecordingPaused,
    required this.showEmojiPicker,
    required this.recordSeconds,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onCancelRecord,
    required this.onTogglePause,
    required this.onEmojiToggle,
    required this.onEmojiSelected,
    required this.onHideEmoji,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (showEmojiPicker && !isRecording)
            SizedBox(
              height: 260,
              child: EmojiPicker(
                onEmojiSelected: (_, emoji) => onEmojiSelected(emoji.emoji),
                config: const Config(
                  emojiViewConfig:
                      EmojiViewConfig(backgroundColor: Color(0xFFF8F9FA)),
                ),
              ),
            ),
          Row(
            children: [
              if (!isRecording) ...[
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.black54),
                  onPressed: onEmojiToggle,
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
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(26)),
                        child: Row(children: [
                          IconButton(
                              tooltip: 'Discard recording',
                              onPressed: onCancelRecord,
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent)),
                          IconButton(
                              tooltip: isRecordingPaused
                                  ? 'Resume recording'
                                  : 'Pause recording',
                              onPressed: onTogglePause,
                              icon: Icon(
                                  isRecordingPaused ? Icons.mic : Icons.pause,
                                  color: const Color(0xFFFF7A00))),
                          Expanded(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                _RecordingWaveform(paused: isRecordingPaused),
                                Text(
                                    '${isRecordingPaused ? 'Paused' : 'Recording'}  $_formatTime',
                                    style: const TextStyle(
                                        color: Color(0xFF2C2C2C),
                                        fontSize: 12)),
                              ])),
                          IconButton(
                              tooltip: 'Stop and send voice message',
                              onPressed: onStopRecord,
                              icon: const Icon(Icons.send_rounded,
                                  color: Color(0xFFFF7A00))),
                        ]),
                      )
                    : TextField(
                        controller: controller,
                        style: const TextStyle(color: Color(0xFF2C2C2C)),
                        maxLines: 4,
                        minLines: 1,
                        onChanged: onChanged,
                        onTap: onHideEmoji,
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
                            borderSide:
                                const BorderSide(color: Color(0xFFFF7A00)),
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
                    onTap: onStartRecord,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ]),
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

class _RecordingWaveform extends StatefulWidget {
  final bool paused;
  const _RecordingWaveform({required this.paused});
  @override
  State<_RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<_RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650))
    ..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 24,
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(22, (i) {
                final wave =
                    math.sin((_controller.value * math.pi * 2) + i * .72).abs();
                final height =
                    widget.paused ? 4.0 : 4 + wave * (5 + (i % 4) * 3);
                return Container(
                    width: 3,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                        color: widget.paused
                            ? Colors.grey
                            : const Color(0xFFFF7A00),
                        borderRadius: BorderRadius.circular(3)));
              }))));
}
