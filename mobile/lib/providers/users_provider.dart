import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UsersProvider extends ChangeNotifier {
  List<UserModel> _allUsers = [];
  List<UserModel> _conversationUsers = [];
  List<String> _onlineUserIds = [];
  bool _loading = false;
  int _pendingLoads = 0;
  bool _usersLoadFailed = false;
  bool _conversationsLoadFailed = false;

  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get conversationUsers => _conversationUsers;
  List<String> get onlineUserIds => _onlineUserIds;
  bool get loading => _loading;
  bool get loadFailed => _usersLoadFailed && _allUsers.isEmpty ||
      _conversationsLoadFailed && _conversationUsers.isEmpty;

  bool isOnline(String userId) => _onlineUserIds.contains(userId);

  void _beginLoad() {
    _pendingLoads++;
    _loading = true;
    notifyListeners();
  }

  void _endLoad() {
    if (_pendingLoads > 0) _pendingLoads--;
    _loading = _pendingLoads > 0;
    notifyListeners();
  }

  void setOnlineUsers(List<String> ids) {
    _onlineUserIds = ids;
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _beginLoad();
    try {
      _allUsers = await ApiService.getUsers();
      _usersLoadFailed = false;
    } catch (_) {
      _usersLoadFailed = true;
    } finally {
      _endLoad();
    }
  }

  Future<void> fetchConversationUsers() async {
    _beginLoad();
    try {
      _conversationUsers = await ApiService.getConversationUsers();
      _conversationsLoadFailed = false;
    } catch (_) {
      _conversationsLoadFailed = true;
    } finally {
      _endLoad();
    }
  }

  List<UserModel> get sidebarUsers {
    final convIds = _conversationUsers.map((u) => u.id).toSet();
    final extras = _allUsers.where((u) => !convIds.contains(u.id)).toList();
    return [..._conversationUsers, ...extras];
  }

  Future<void> togglePinnedChat(String userId) async {
    final ok = await ApiService.togglePinnedChat(userId);
    if (!ok) return;
    UserModel update(UserModel user) =>
        user.id == userId ? user.copyWith(isPinned: !user.isPinned) : user;
    _conversationUsers = _conversationUsers.map(update).toList()
      ..sort((a, b) => (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0));
    _allUsers = _allUsers.map(update).toList();
    notifyListeners();
  }
}
