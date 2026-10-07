import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

typedef MessageCallback = void Function(MessageModel message);
typedef MessageIdCallback = void Function(String messageId);
typedef MessageUpdatedCallback = void Function(MessageModel message);
typedef OnlineUsersCallback = void Function(List<String> userIds);
typedef TypingCallback = void Function(String senderId);
typedef SeenCallback = void Function(String receiverId);
typedef ConversationActivityCallback = void Function(Map<String, dynamic> activity);

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  IO.Socket? _socket;
  bool _initialized = false;

  // Callbacks registered by the UI
  MessageCallback? onReceiveMessage;
  MessageIdCallback? onMessageDeleted;
  MessageUpdatedCallback? onMessageUpdated;
  MessageUpdatedCallback? onMessageReaction;
  OnlineUsersCallback? onOnlineUsers;
  TypingCallback? onTyping;
  TypingCallback? onStopTyping;
  SeenCallback? onMessagesSeen;
  ConversationActivityCallback? onConversationActivity;

  void init(String userId, String token) {
    if (_initialized) return;
    _initialized = true;

    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('🟢 Socket connected');
      _socket!.emit('registerUser', userId);
    });

    _socket!.onDisconnect((_) => debugPrint('🔴 Socket disconnected'));

    _socket!.on('receiveMessage', (data) {
      try {
        final msg =
            MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
        onReceiveMessage?.call(msg);
      } catch (e) {
        debugPrint('Socket receiveMessage parse error: $e');
      }
    });

    _socket!.on('conversationActivity', (data) {
      if (data is Map) {
        final activity = Map<String, dynamic>.from(data);
        onConversationActivity?.call(activity);
        final sender = activity['user'];
        final senderName = sender is Map
            ? sender['name']?.toString() ?? 'Someone'
            : 'Someone';
        unawaited(NotificationService.showIncomingMessage(
          senderName: senderName,
          isPrivate: activity['requiresChatLock'] == true,
        ).catchError((_) {}));
      }
    });

    _socket!.on('messageDeleted', (data) {
      final id = (data as Map)['messageId']?.toString();
      if (id != null) onMessageDeleted?.call(id);
    });

    _socket!.on('messageUpdated', (data) {
      try {
        final msg =
            MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
        onMessageUpdated?.call(msg);
      } catch (e) {
        debugPrint('Socket messageUpdated parse error: $e');
      }
    });

    _socket!.on('messageReaction', (data) {
      try {
        final msg =
            MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
        onMessageReaction?.call(msg);
      } catch (e) {
        debugPrint('Socket messageReaction parse error: $e');
      }
    });

    _socket!.on('onlineUsers', (data) {
      final ids = (data as List<dynamic>).map((e) => e.toString()).toList();
      onOnlineUsers?.call(ids);
    });

    _socket!.on('typing', (data) {
      final senderId = (data as Map)['senderId']?.toString();
      if (senderId != null) onTyping?.call(senderId);
    });

    _socket!.on('stopTyping', (data) {
      final senderId = (data as Map)['senderId']?.toString();
      if (senderId != null) onStopTyping?.call(senderId);
    });

    _socket!.on('messagesSeenUpdate', (data) {
      final receiverId = (data as Map)['receiverId']?.toString();
      if (receiverId != null) onMessagesSeen?.call(receiverId);
    });
  }

  void emitTyping(String senderId, String receiverId) {
    _socket?.emit('typing', {'senderId': senderId, 'receiverId': receiverId});
  }

  void emitStopTyping(String senderId, String receiverId) {
    _socket
        ?.emit('stopTyping', {'senderId': senderId, 'receiverId': receiverId});
  }

  void emitMessagesSeen(String senderId, String receiverId) {
    _socket?.emit(
        'messagesSeen', {'senderId': senderId, 'receiverId': receiverId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _initialized = false;
  }
}
