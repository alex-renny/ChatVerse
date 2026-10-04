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
    if (_searchQuery.isEmpty) return users.conversationUsers;
    return users.allUsers
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth),
            _buildSearchBar(),
            Expanded(
              child: users.loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFF7A00)))
                  : RefreshIndicator(
                      color: const Color(0xFFFF7A00),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (val == 'search') {
                setState(() => _showSearch = true);
              } else if (val == 'logout') {
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'search', child: Text('Search')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('💬', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      leading: Stack(
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
      title: Text(
        user.name,
        style: const TextStyle(
          color: Color(0xFF2C2C2C),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        isOnline ? 'Online' : user.status,
        style: TextStyle(
          color: isOnline ? Colors.green : Colors.grey,
          fontSize: 13,
        ),
      ),
      trailing: IconButton(
        tooltip: user.isPinned ? 'Unpin chat' : 'Pin chat',
        icon: Icon(user.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: user.isPinned ? const Color(0xFFFF7A00) : Colors.grey),
        onPressed: () =>
            context.read<UsersProvider>().togglePinnedChat(user.id),
      ),
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
