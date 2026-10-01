import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../widgets/user_avatar.dart';
import 'chat/chat_screen.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  int _selectedTab = 0; // 0 = conversations, 1 = all users

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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredUsers {
    final users = context.read<UsersProvider>();
    final list = _selectedTab == 0 ? users.conversationUsers : users.allUsers;
    if (_searchQuery.isEmpty) return list;
    return list
        .where((u) =>
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = context.watch<UsersProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F23),
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('ChatVerse',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search,
                color: Colors.white70),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _searchQuery = '';
              }
            }),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: UserAvatar(
                url: auth.user?.profilePic,
                name: auth.user?.name ?? '',
                radius: 18,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              children: [
                _tabButton('Chats', 0),
                _tabButton('People', 1),
              ],
            ),
          ),
        ),
      ),
      body: users.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              color: const Color(0xFF7C3AED),
              onRefresh: () async {
                await users.fetchConversationUsers();
                await users.fetchUsers();
              },
              child: _filteredUsers.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (ctx, i) =>
                          _UserTile(user: _filteredUsers[i]),
                    ),
            ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isActive ? const Color(0xFF7C3AED) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? const Color(0xFF7C3AED) : Colors.white38,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTab == 0
                ? Icons.chat_bubble_outline
                : Icons.people_outline,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0
                ? 'No conversations yet\nStart chatting!'
                : 'No users found',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final onlineIds = context.watch<UsersProvider>().onlineUserIds;
    final isOnline = onlineIds.contains(user.id);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(url: user.profilePic, name: user.name, radius: 26),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0A0A1A), width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.name,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isOnline ? 'Online' : user.status,
        style: TextStyle(
          color: isOnline ? Colors.greenAccent : Colors.white38,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {
        context.read<ChatProvider>().clearConversation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(partner: user)),
        );
      },
    );
  }
}
