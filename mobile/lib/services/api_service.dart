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
    final response = await http.get(
      Uri.parse(ApiConfig.users),
      headers: await _headers(),
    );
    if (response.statusCode != 200) return [];
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  static Future<List<UserModel>> getConversationUsers() async {
    final response = await http.get(
      Uri.parse(ApiConfig.conversations),
      headers: await _headers(),
    );
    if (response.statusCode != 200) return [];
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMessages(
    String receiverId, {
    int limit = 30,
    int skip = 0,
  }) async {
    final uri = Uri.parse(ApiConfig.messages(receiverId))
        .replace(queryParameters: {
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
          ? MessageModel.fromJson(
              data['pinnedMessage'] as Map<String, dynamic>)
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
    request.files.add(await http.MultipartFile.fromPath('attachment', file.path));

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
}
