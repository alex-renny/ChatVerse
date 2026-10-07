import 'dart:convert';
import 'dart:async';
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
    try {
      final secure = await _secureStorage
          .read(key: _tokenKey)
          .timeout(const Duration(seconds: 6));
      if (secure != null) return secure;
    } catch (error) {
      debugPrint('Secure token storage unavailable: $error');
    }
    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString(_tokenKey);
    if (oldToken != null) {
      try {
        await _secureStorage.write(key: _tokenKey, value: oldToken)
            .timeout(const Duration(seconds: 6));
        await prefs.remove(_tokenKey);
      } catch (_) {
        // Keep using the legacy preference token if secure storage is unavailable.
      }
    }
    return oldToken;
  }

  static Future<void> _saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _secureStorage.write(key: _tokenKey, value: token)
          .timeout(const Duration(seconds: 6));
      await prefs.remove(_tokenKey);
    } catch (error) {
      debugPrint('Secure token storage unavailable; saving session locally: $error');
      await prefs.setString(_tokenKey, token);
    }
    await prefs.setString(_userKey, user.toJsonString());
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _secureStorage.delete(key: _tokenKey)
          .timeout(const Duration(seconds: 6));
    } catch (error) {
      debugPrint('Secure token cleanup failed: $error');
    }
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _saveSession(token, user);
        return {
          'success': true,
          'message': data['message'],
          'user': user,
          'token': token,
        };
      }
      final message = data['message']?.toString() ?? 'Registration failed';
      if (message.toLowerCase().contains('already exists')) {
        final recovered = await login(email: email, password: password);
        if (recovered['success'] == true) return recovered;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Auth error: $e');
      // The server may have created the account even if the registration
      // response was lost. Try signing in to recover that successful create.
      final recovered = await login(email: email, password: password);
      if (recovered['success'] == true) return recovered;
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
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(ApiConfig.login),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 45));
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Unexpected login response');
        }
        if (response.statusCode == 200) {
          final token = decoded['token'] as String;
          final user =
              UserModel.fromJson(decoded['user'] as Map<String, dynamic>);
          await _saveSession(token, user);
          return {'success': true, 'user': user, 'token': token};
        }
        if (response.statusCode >= 500 && attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        return {
          'success': false,
          'code': decoded['code'],
          'message': decoded['message'] ?? 'Login failed',
        };
      } catch (error) {
        debugPrint('Login attempt ${attempt + 1} failed: $error');
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        return {
          'success': false,
          'message': 'Could not reach ReSender. Check your connection and try again.'
        };
      }
    }
    return {'success': false, 'message': 'Login failed. Please try again.'};
  }

  static Future<Map<String, dynamic>> validateSession(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.authSession),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      return {
        'success': response.statusCode == 200,
        'unauthorized': response.statusCode == 401,
      };
    } catch (_) {
      return {'success': false, 'networkError': true};
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
      UserModel? updatedUser;
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
            await request.send().timeout(const Duration(seconds: 60));
        final picResponse = await http.Response.fromStream(streamed)
            .timeout(const Duration(seconds: 60));
        if (picResponse.statusCode != 200) {
          final error = jsonDecode(picResponse.body);
          return {
            'success': false,
            'message': error is Map ? error['message'] ?? 'Profile picture upload failed' : 'Profile picture upload failed',
          };
        }
        final picData = jsonDecode(picResponse.body);
        if (picData is Map<String, dynamic>) {
          final rawUser = picData['user'] is Map ? picData['user'] : picData;
          updatedUser = UserModel.fromJson(Map<String, dynamic>.from(rawUser));
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
          final rawUser = data['user'] is Map ? data['user'] : data;
          updatedUser = UserModel.fromJson(Map<String, dynamic>.from(rawUser));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, updatedUser.toJsonString());
          return {'success': true, 'user': updatedUser};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Update failed'
        };
      }

      if (updatedUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, updatedUser.toJsonString());
        return {'success': true, 'user': updatedUser};
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
