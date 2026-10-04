import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const _tokenKey = 'chatverse_token';
  static const _userKey = 'chatverse_user';
  static const _secureStorage = FlutterSecureStorage();

  // ── Token helpers ─────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final secure = await _secureStorage.read(key: _tokenKey);
    if (secure != null) return secure;
    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString(_tokenKey);
    if (oldToken != null) {
      await _secureStorage.write(key: _tokenKey, value: oldToken);
      await prefs.remove(_tokenKey);
    }
    return oldToken;
  }

  static Future<void> _saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _tokenKey, value: token);
    await prefs.setString(_userKey, user.toJsonString());
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _tokenKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  // ── Auth API calls ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'name': name, 'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed'
      };
    } catch (e) {
      debugPrint('Auth error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet.'
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _saveSession(token, user);
        return {'success': true, 'user': user, 'token': token};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      debugPrint('Auth error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet.'
      };
    }
  }

  // ── Profile update ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? bio,
    String? status,
    File? profilePicFile,
  }) async {
    final token = await getToken();
    if (token == null)
      return {'success': false, 'message': 'Not authenticated'};

    try {
      // Upload profile picture if provided
      if (profilePicFile != null) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse(ApiConfig.profilePicture),
        )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(await http.MultipartFile.fromPath(
            'profile',
            profilePicFile.path,
          ));

        final streamed =
            await request.send().timeout(const Duration(seconds: 15));
        final picResponse = await http.Response.fromStream(streamed);
        if (picResponse.statusCode != 200) {
          return {'success': false, 'message': 'Profile picture upload failed'};
        }
      }

      // Update name / bio / status
      if (name != null || bio != null || status != null) {
        final body = <String, dynamic>{};
        if (name != null) body['name'] = name;
        if (bio != null) body['bio'] = bio;
        if (status != null) body['status'] = status;

        final response = await http
            .put(
              Uri.parse(ApiConfig.updateProfile),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200) {
          final updatedUser =
              UserModel.fromJson(data['user'] as Map<String, dynamic>);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, updatedUser.toJsonString());
          return {'success': true, 'user': updatedUser};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Update failed'
        };
      }

      return {'success': true};
    } catch (e) {
      debugPrint('Auth error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet.'
      };
    }
  }
}
