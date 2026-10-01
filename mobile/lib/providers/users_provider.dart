import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UsersProvider extends ChangeNotifier {
  List<UserModel> _allUsers = [];
  List<UserModel> _conversationUsers = [];
  List<String> _onlineUserIds = [];
  bool _loading = false;

  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get conversationUsers => _conversationUsers;
  List<String> get onlineUserIds => _onlineUserIds;
  bool get loading => _loading;

  bool isOnline(String userId) => _onlineUserIds.contains(userId);

  void setOnlineUsers(List<String> ids) {
    _onlineUserIds = ids;
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _loading = true;
    notifyListeners();
    _allUsers = await ApiService.getUsers();
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchConversationUsers() async {
    _loading = true;
    notifyListeners();
    _conversationUsers = await ApiService.getConversationUsers();
    _loading = false;
    notifyListeners();
  }

  List<UserModel> get sidebarUsers {
    final convIds = _conversationUsers.map((u) => u.id).toSet();
    final extras = _allUsers.where((u) => !convIds.contains(u.id)).toList();
    return [..._conversationUsers, ...extras];
  }
}
