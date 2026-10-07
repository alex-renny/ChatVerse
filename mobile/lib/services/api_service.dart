import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Users ──────────────────────────────────────────────────────────────────
  static Future<List<UserModel>> getUsers() async {
    final response = await http
        .get(Uri.parse(ApiConfig.users), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return [];
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  static Future<List<UserModel>> getConversationUsers() async {
    final response = await http
        .get(Uri.parse(ApiConfig.conversations), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return [];
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> getAdminOverview(String password) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.adminOverview),
          headers: await _headers(),
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 30));
    final data = _decodeObjectResponse(
      response,
      unavailableMessage:
          'The admin dashboard is missing from the deployed server. Deploy the latest server code and try again.',
    );
    if (data is Map<String, dynamic>) {
      if (response.statusCode == 200) return data;
      throw Exception(data['message']?.toString() ?? 'Unable to load admin data');
    }
    throw Exception('Unable to load admin data');
  }

  static Future<Map<String, dynamic>> updateAdminPasswordPolicy(
      String password, bool allow) async {
    return _adminRequest(
      'PUT',
      ApiConfig.adminPasswordPolicy,
      {'password': password, 'allowUserPasswordChange': allow},
    );
  }

  static Future<Map<String, dynamic>> reviewPasswordRequest(
      String adminPassword, String userId, bool approve) async {
    return _adminRequest(
      'POST',
      ApiConfig.adminPasswordRequest(userId),
      {'password': adminPassword, 'approve': approve},
    );
  }

  static Future<Map<String, dynamic>> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _adminRequest('PUT', ApiConfig.adminPassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.changePassword),
          headers: await _headers(),
          body: jsonEncode({
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final data = _decodeObjectResponse(response,
        unavailableMessage: 'The server returned an invalid response');
    if (response.statusCode == 200 || response.statusCode == 202) return data;
    throw Exception(data['message']?.toString() ?? 'Could not change password');
  }

  static Future<Map<String, dynamic>> _adminRequest(
      String method, String url, Map<String, dynamic> body) async {
    final uri = Uri.parse(url);
    final headers = await _headers();
    final request = method == 'PUT'
        ? http.put(uri, headers: headers, body: jsonEncode(body))
        : http.post(uri, headers: headers, body: jsonEncode(body));
    final response = await request.timeout(const Duration(seconds: 20));
    final data = _decodeObjectResponse(response,
        unavailableMessage:
            'The admin dashboard is missing from the deployed server. Deploy the latest server code and try again.');
    if (response.statusCode == 200) return data;
    throw Exception(data['message']?.toString() ?? 'Admin action failed');
  }

  static Map<String, dynamic> _decodeObjectResponse(
      http.Response response, {required String unavailableMessage}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // A stale deployment can return an HTML 404 page instead of JSON.
    }
    throw Exception(unavailableMessage);
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMessages(
    String receiverId, {
    int limit = 30,
    int skip = 0,
  }) async {
    final uri =
        Uri.parse(ApiConfig.messages(receiverId)).replace(queryParameters: {
      'limit': limit.toString(),
      'skip': skip.toString(),
    });
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final msgs = (data['messages'] as List<dynamic>)
          .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList();
      final pinned = data['pinnedMessage'] != null
          ? MessageModel.fromJson(data['pinnedMessage'] as Map<String, dynamic>)
          : null;
      return {'messages': msgs, 'pinnedMessage': pinned};
    }
    if (response.statusCode == 403) {
      return {'error': 'chat_password_required'};
    }
    return {'messages': <MessageModel>[], 'pinnedMessage': null};
  }

  static Future<MessageModel?> sendTextMessage({
    required String receiverId,
    required String text,
    String? replyToId,
  }) async {
    final token = await AuthService.getToken();
    final body = <String, dynamic>{'receiver': receiverId, 'text': text};
    if (replyToId != null) body['replyTo'] = replyToId;

    final response = await http.post(
      Uri.parse(ApiConfig.sendMessage()),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return MessageModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<MessageModel?> sendFileMessage({
    required String receiverId,
    required File file,
    String? text,
    String? replyToId,
    bool isVoice = false,
  }) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.sendMessage()),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['receiver'] = receiverId
      ..fields['isVoice'] = isVoice.toString();
    if (text != null && text.isNotEmpty) request.fields['text'] = text;
    if (replyToId != null) request.fields['replyTo'] = replyToId;
    request.files
        .add(await http.MultipartFile.fromPath('attachment', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) {
      return MessageModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<bool> deleteMessage(
    String messageId, {
    bool deleteForEveryone = false,
  }) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.deleteMessage(messageId)),
      headers: await _headers(),
      body: jsonEncode({'deleteForEveryone': deleteForEveryone}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> markAsSeen(String senderId) async {
    final response = await http.put(
      Uri.parse(ApiConfig.markSeen(senderId)),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  static Future<MessageModel?> reactToMessage(
      String messageId, String emoji) async {
    final response = await http.put(
      Uri.parse(ApiConfig.reactMessage(messageId)),
      headers: await _headers(),
      body: jsonEncode({'emoji': emoji}),
    );
    if (response.statusCode == 200) {
      return MessageModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<MessageModel?> pinMessage(String messageId) async {
    final response = await http.put(
      Uri.parse(ApiConfig.pinMessage(messageId)),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return MessageModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<MessageModel?> unpinMessage(String messageId) async {
    final response = await http.put(
      Uri.parse(ApiConfig.unpinMessage(messageId)),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return MessageModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<bool> clearChat(String receiverId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.clearChat(receiverId)),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> togglePinnedChat(String userId) async {
    final response = await http.put(Uri.parse(ApiConfig.pinChat(userId)),
        headers: await _headers());
    return response.statusCode == 200;
  }

  static Future<String> getChatBackground(String userId) async {
    final response = await http.get(Uri.parse(ApiConfig.chatBackground(userId)),
        headers: await _headers());
    if (response.statusCode != 200) return '';
    return (jsonDecode(response.body) as Map<String, dynamic>)['background']
            ?.toString() ??
        '';
  }

  static Future<bool> saveChatBackground(
      String userId, String background) async {
    final response = await http.put(Uri.parse(ApiConfig.chatBackground(userId)),
        headers: await _headers(),
        body: jsonEncode({'background': background}));
    return response.statusCode == 200;
  }

  static Future<bool> isChatPasswordEnabled(String userId) async {
    final response = await http.get(
        Uri.parse(ApiConfig.chatPasswordEnabled(userId)),
        headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Unable to verify chat privacy');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['enabled'] == true && data['verified'] != true;
  }

  static Future<bool> chatPasswordEnabledForMe() async {
    final response = await http.get(Uri.parse(ApiConfig.chatPassword),
        headers: await _headers());
    if (response.statusCode != 200) return false;
    return (jsonDecode(response.body) as Map<String, dynamic>)['enabled'] ==
        true;
  }

  static Future<Map<String, dynamic>> getChatPasswordStatus() async {
    final response = await http.get(Uri.parse(ApiConfig.chatPassword),
        headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Unable to load chat access list');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = (data['verifiedUsers'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((user) => UserModel.fromJson(Map<String, dynamic>.from(user)))
        .toList();
    return {'enabled': data['enabled'] == true, 'users': users};
  }

  static Future<bool> removeChatAccess(String userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.chatPassword}/access/$userId'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> verifyChatPassword(String userId, String password) async {
    final response = await http.post(Uri.parse(ApiConfig.verifyChatPassword),
        headers: await _headers(),
        body: jsonEncode({'userId': userId, 'password': password}));
    return response.statusCode == 200;
  }

  static Future<bool> setChatPassword(String password) async {
    final response = await http.put(Uri.parse(ApiConfig.chatPassword),
        headers: await _headers(), body: jsonEncode({'password': password}));
    return response.statusCode == 200;
  }

  static Future<bool> removeChatPassword() async {
    final response = await http.delete(Uri.parse(ApiConfig.chatPassword),
        headers: await _headers());
    return response.statusCode == 200;
  }
}
