import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/password_prompt_dialog.dart';
import '../widgets/animated_page_route.dart';
import '../widgets/resender_loader.dart';
import '../services/api_service.dart';
import 'chat/chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final users = context.read<UsersProvider>();
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    chat.init(auth.user!.id);
    users.fetchConversationUsers();
    users.fetchUsers();

    // Register online users callback
    SocketService.instance.onOnlineUsers = (ids) {
      users.setOnlineUsers(ids);
    };
    SocketService.instance.onConversationActivity = users.handleConversationActivity;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredUsers {
    final users = context.read<UsersProvider>();
    if (_searchQuery.isEmpty) return users.conversationUsers;
    final query = _searchQuery.trim().toLowerCase();
    if (query.length < 3) return const [];
    return users.allUsers.where((user) {
      final name = user.name.trim().toLowerCase();
      final email = user.email.trim().toLowerCase();
      return name.startsWith(query) || email.startsWith(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = context.watch<UsersProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                      color: const Color(0xFFFF7A00),
                      onRefresh: () async {
                        await users.fetchConversationUsers();
                        await users.fetchUsers();
                      },
                      child: users.loading && _filteredUsers.isEmpty
                          ? const Center(child: ResenderLoader(showLabel: true))
                          : users.loadFailed && _filteredUsers.isEmpty
                          ? _connectionErrorState(users)
                          : _filteredUsers.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (ctx, i) =>
                                  TweenAnimationBuilder<double>(
                                key: ValueKey(_filteredUsers[i].id),
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                    milliseconds: 260 + ((i < 8 ? i : 8) * 35)),
                                curve: Curves.easeOutCubic,
                                builder: (_, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - value) * 10),
                                    child: child,
                                  ),
                                ),
                                child: _UserTile(
                                  user: _filteredUsers[i],
                                  isConversation: users.conversationUsers.any(
                                      (u) => u.id == _filteredUsers[i].id),
                                ),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ReSender',
                style: TextStyle(
                  color: Color(0xFFFF7A00),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Welcome back, ${auth.user?.name ?? ''}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2C2C2C)),
            onSelected: (val) async {
              if (val == 'profile') {
                Navigator.push(
                    context, animatedPageRoute(const ProfileScreen()));
              } else if (val == 'search') {
                setState(() => _showSearch = true);
              } else if (val == 'logout') {
                await context.read<AuthProvider>().logout();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  Icon(Icons.settings_outlined, size: 19),
                  SizedBox(width: 10),
                  Text('Profile & settings')
                ]),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(children: [
                  Icon(Icons.search, size: 19),
                  SizedBox(width: 10),
                  Text('Search contacts')
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 19, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Log out', style: TextStyle(color: Colors.redAccent))
                ]),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    if (_showSearch) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF7A00)),
        ),
        child: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _showSearch = false;
                  _searchCtrl.clear();
                  _searchQuery = '';
                });
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => setState(() => _showSearch = true),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text('Search contacts...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }

  Widget _emptyState() {
    final needsMoreLetters = _showSearch && _searchQuery.trim().length < 3;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💬', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              needsMoreLetters ? 'Search your friends...' : 'No users found',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              needsMoreLetters
                  ? 'Matching starts at the beginning of a name or email.'
                  : 'Try a different starting prefix.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _connectionErrorState(UsersProvider users) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .2),
          const Icon(Icons.cloud_off_outlined,
              size: 44, color: Color(0xFFFF7A00)),
          const SizedBox(height: 12),
          const Center(
              child: Text('Could not connect to ReSender',
                  style: TextStyle(
                      color: Color(0xFF2C2C2C),
                      fontSize: 16,
                      fontWeight: FontWeight.w600))),
          const SizedBox(height: 6),
          const Center(
              child: Text('Check your connection and try again.',
                  style: TextStyle(color: Colors.grey))),
          Center(
              child: TextButton.icon(
            onPressed: () {
              users.fetchConversationUsers();
              users.fetchUsers();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          )),
        ],
      );
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isConversation;
  const _UserTile({required this.user, required this.isConversation});

  String _recentLabel(DateTime? timestamp) {
    if (timestamp == null) return '';
    final local = timestamp.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${local.day}/${local.month}';
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      final needsPassword = await ApiService.isChatPasswordEnabled(user.id);
      if (!context.mounted) return;
      if (needsPassword) {
        final password = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PasswordPromptDialog(
            title: 'Private chat',
            hint: 'Enter chat password to continue',
            confirmLabel: 'Unlock chat',
          ),
        );
        if (password == null) return;
        final unlocked = await ApiService.verifyChatPassword(user.id, password);
        if (!context.mounted) return;
        if (!unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Incorrect password. Chat was not opened.')),
          );
          return;
        }
      }
      if (!context.mounted) return;
      context.read<ChatProvider>().clearConversation();
      Navigator.push(context, animatedPageRoute(ChatScreen(partner: user)));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not check chat privacy. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineIds = context.watch<UsersProvider>().onlineUserIds;
    final isOnline = onlineIds.contains(user.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openChat(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0F1F3)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 3))
              ],
            ),
            child: Row(children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(url: user.profilePic, name: user.name, radius: 24),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
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
                    Row(children: [
                      Expanded(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2C2C2C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_recentLabel(user.lastMessageAt).isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(_recentLabel(user.lastMessageAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ],
                    ),
                    const SizedBox(height: 3),
                    if (user.lastMessagePreview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user.lastMessagePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: user.requiresChatLock
                              ? const Color(0xFFFF7A00)
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ] else Row(children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text(
                        isOnline ? 'Online' : user.status,
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontSize: 13,
                        ),
                      )),
                    ]),
                  ])),
              if (user.unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7A00), shape: BoxShape.circle),
                  child: Text('${user.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              PopupMenuButton<String>(
                tooltip: 'Chat options',
                onSelected: (value) async {
                  if (value == 'pin') {
                    await context.read<UsersProvider>().togglePinnedChat(user.id);
                  } else if (value == 'delete' && isConversation) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete chat?'),
                        content: Text('Delete your message history with ${user.name}? This only removes it from your account.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      final ok = await context.read<UsersProvider>().deleteConversation(user.id);
                      if (context.mounted && !ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not delete this chat. Try again.')));
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'pin', child: Text(user.isPinned ? 'Unpin chat' : 'Pin chat')),
                  if (isConversation)
                    const PopupMenuItem(value: 'delete', child: Text('Delete chat', style: TextStyle(color: Colors.red))),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B5BC)),
            ]),
          ),
        ),
      ),
    );
  }
}
