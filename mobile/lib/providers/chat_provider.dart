import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  List<MessageModel> _messages = [];
  MessageModel? _pinnedMessage;
  bool _loading = false;
  bool _sending = false;
  String? _error;
  MessageModel? _replyingTo;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _partnerIsTyping = false;
  String? _currentPartnerId;
  String? _currentUserId;
  int _skip = 0;
  bool _hasMore = true;
  static const int _limit = 30;

  List<MessageModel> get messages => _messages;
  MessageModel? get pinnedMessage => _pinnedMessage;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;
  MessageModel? get replyingTo => _replyingTo;
  bool get partnerIsTyping => _partnerIsTyping;
  bool get hasMore => _hasMore;

  void init(String currentUserId) {
    _currentUserId = currentUserId;
    _registerSocketCallbacks();
  }

  void _registerSocketCallbacks() {
    final socket = SocketService.instance;

    socket.onReceiveMessage = (msg) {
      if (_currentPartnerId == null) return;
      if ((msg.senderId == _currentPartnerId &&
              msg.receiverId == _currentUserId) ||
          (msg.senderId == _currentUserId &&
              msg.receiverId == _currentPartnerId)) {
        _messages.insert(0, msg);
        notifyListeners();
      }
    };

    socket.onMessageDeleted = (messageId) {
      _messages.removeWhere((m) => m.id == messageId);
      if (_pinnedMessage?.id == messageId) _pinnedMessage = null;
      notifyListeners();
    };

    socket.onMessageUpdated = (updated) {
      final idx = _messages.indexWhere((m) => m.id == updated.id);
      if (idx != -1) _messages[idx] = updated;
      if (_pinnedMessage?.id == updated.id) _pinnedMessage = updated;
      if (updated.pinned) _pinnedMessage = updated;
      notifyListeners();
    };

    socket.onMessageReaction = (updated) {
      final idx = _messages.indexWhere((m) => m.id == updated.id);
      if (idx != -1) {
        _messages[idx] = updated;
        notifyListeners();
      }
    };

    socket.onTyping = (senderId) {
      if (senderId == _currentPartnerId) {
        _partnerIsTyping = true;
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          _partnerIsTyping = false;
          notifyListeners();
        });
      }
    };

    socket.onStopTyping = (senderId) {
      if (senderId == _currentPartnerId) {
        _partnerIsTyping = false;
        notifyListeners();
      }
    };

    socket.onMessagesSeen = (receiverId) {
      if (receiverId == _currentPartnerId) {
        _messages = _messages
            .map((m) =>
                m.senderId == _currentUserId && m.receiverId == receiverId
                    ? m.copyWith(seen: true)
                    : m)
            .toList();
        notifyListeners();
      }
    };
  }

  Future<void> loadMessages(String partnerId, {bool refresh = false}) async {
    if (refresh) {
      _skip = 0;
      _hasMore = true;
      _messages = [];
    }
    if (_loading || (!_hasMore && !refresh)) return;

    _currentPartnerId = partnerId;
    _loading = true;
    _error = null;
    notifyListeners();

    final result =
        await ApiService.getMessages(partnerId, limit: _limit, skip: _skip);

    _loading = false;
    if (result.containsKey('error')) {
      _error = result['error'] as String;
      notifyListeners();
      return;
    }

    final fetched = result['messages'] as List<MessageModel>;
    if (refresh) {
      _messages = fetched;
    } else {
      final known = _messages.map((m) => m.id).toSet();
      _messages = [
        ..._messages,
        ...fetched.where((m) => !known.contains(m.id))
      ];
    }
    _pinnedMessage = result['pinnedMessage'] as MessageModel?;

    if (fetched.length < _limit) _hasMore = false;
    _skip += fetched.length;
    notifyListeners();
  }

  Future<void> loadMore(String partnerId) => loadMessages(partnerId);

  Future<bool> sendText(String text, String receiverId) async {
    if (text.trim().isEmpty) return false;
    final optimisticId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final optimistic = MessageModel(
      id: optimisticId,
      senderId: _currentUserId ?? '',
      receiverId: receiverId,
      text: text.trim(),
      replyTo: _replyingTo,
      createdAt: now,
      updatedAt: now,
      isSending: true,
    );
    _messages.insert(0, optimistic);
    _sending = true;
    notifyListeners();

    MessageModel? msg;
    try {
      msg = await ApiService.sendTextMessage(
        receiverId: receiverId,
        text: text.trim(),
        replyToId: _replyingTo?.id,
      );
    } catch (_) {
      msg = null;
    }
    _replyingTo = null;
    _sending = false;
    if (msg != null) {
      final index = _messages.indexWhere((m) => m.id == optimisticId);
      if (index >= 0) _messages[index] = msg;
    } else {
      _messages.removeWhere((m) => m.id == optimisticId);
      _error =
          'Message could not be sent. Check your connection and try again.';
    }
    notifyListeners();
    return msg != null;
  }

  Future<void> sendFile(File file, String receiverId,
      {bool isVoice = false}) async {
    _sending = true;
    notifyListeners();

    final msg = await ApiService.sendFileMessage(
      receiverId: receiverId,
      file: file,
      replyToId: _replyingTo?.id,
      isVoice: isVoice,
    );
    _replyingTo = null;
    _sending = false;
    if (msg != null) {
      _messages.insert(0, msg);
    }
    notifyListeners();
  }

  void setReplyingTo(MessageModel? msg) {
    _replyingTo = msg;
    notifyListeners();
  }

  void onInputChanged(String value, String senderId, String receiverId) {
    if (value.isNotEmpty && !_isTyping) {
      _isTyping = true;
      SocketService.instance.emitTyping(senderId, receiverId);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      SocketService.instance.emitStopTyping(senderId, receiverId);
    });
  }

  Future<void> deleteMessage(String messageId,
      {bool deleteForEveryone = false}) async {
    await ApiService.deleteMessage(messageId,
        deleteForEveryone: deleteForEveryone);
    if (deleteForEveryone) {
      _messages.removeWhere((m) => m.id == messageId);
      if (_pinnedMessage?.id == messageId) _pinnedMessage = null;
    } else {
      _messages.removeWhere((m) => m.id == messageId);
    }
    notifyListeners();
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    final updated = await ApiService.reactToMessage(messageId, emoji);
    if (updated != null) {
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) _messages[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> pinMessage(String messageId) async {
    final updated = await ApiService.pinMessage(messageId);
    if (updated != null) {
      _pinnedMessage = updated;
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) _messages[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> unpinMessage(String messageId) async {
    final updated = await ApiService.unpinMessage(messageId);
    if (updated != null) {
      _pinnedMessage = null;
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) _messages[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> clearChat(String receiverId) async {
    await ApiService.clearChat(receiverId);
    _messages = [];
    _pinnedMessage = null;
    notifyListeners();
  }

  void markMessagesSeen(String senderId, String receiverId) {
    ApiService.markAsSeen(senderId);
    _messages = _messages
        .map((m) => m.senderId == senderId ? m.copyWith(seen: true) : m)
        .toList();
    SocketService.instance.emitMessagesSeen(senderId, receiverId);
    notifyListeners();
  }

  void clearConversation() {
    _currentPartnerId = null;
    _messages = [];
    _pinnedMessage = null;
    _replyingTo = null;
    _partnerIsTyping = false;
    _skip = 0;
    _hasMore = true;
    _typingTimer?.cancel();
    notifyListeners();
  }
}
