import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  AuthStatus _status = AuthStatus.initial;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _token = await AuthService.getToken();
    _user = await AuthService.getSavedUser();

    if (_token != null && _user != null) {
      _status = AuthStatus.authenticated;
      SocketService.instance.init(_user!.id, _token!);
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      if (result['success'] == true) {
        _user = result['user'] as UserModel;
        _token = result['token'] as String;
        _status = AuthStatus.authenticated;
        SocketService.instance.init(_user!.id, _token!);
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String?;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error or timeout';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.register(
              name: name, email: email, password: password)
          .timeout(const Duration(seconds: 15));
      _status = AuthStatus.unauthenticated;
      if (result['success'] != true) {
        _error = result['message'] as String?;
      }
      notifyListeners();
      return result['success'] == true;
    } catch (e) {
      _error = 'Connection error or timeout';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? status,
    File? profilePicFile,
  }) async {
    final result = await AuthService.updateProfile(
      name: name,
      bio: bio,
      status: status,
      profilePicFile: profilePicFile,
    );
    if (result['success'] == true && result['user'] != null) {
      _user = result['user'] as UserModel;
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateUserLocally(UserModel updated) {
    _user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.clearSession();
    SocketService.instance.disconnect();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
