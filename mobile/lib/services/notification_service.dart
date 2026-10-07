import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static const _channel = MethodChannel('com.resender/notifications');
  static const _enabledKey = 'message_notifications_enabled';

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? true;
  }

  static Future<bool> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    if (!enabled) {
      await preferences.setBool(_enabledKey, false);
      return true;
    }
    try {
      final permission = await Permission.notification.request();
      await preferences.setBool(_enabledKey, permission.isGranted);
      return permission.isGranted;
    } catch (_) {
      await preferences.setBool(_enabledKey, false);
      return false;
    }
  }

  static Future<void> requestPermissionIfEnabled() async {
    try {
      if (!await isEnabled()) return;
      var permission = await Permission.notification.status;
      if (!permission.isGranted) {
        permission = await Permission.notification.request();
      }
      if (!permission.isGranted) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_enabledKey, false);
      }
    } catch (_) {
      // Keep notification permission problems from blocking app startup.
    }
  }

  static Future<bool> openSystemSettings() => openAppSettings();

  static Future<void> showIncomingMessage({
    required String senderName,
    required bool isPrivate,
  }) async {
    try {
      if (!await isEnabled()) return;
      final permission = await Permission.notification.status;
      if (!permission.isGranted) return;
      await _channel.invokeMethod<void>('showIncomingMessage', {
        'title': isPrivate ? 'Private message from $senderName' : 'New message from $senderName',
        'body': isPrivate
            ? 'Unlock the chat to read this message.'
            : 'You have a new message in ReSender.',
        'id': DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      });
    } on PlatformException {
      // Notification failures should not interrupt message delivery.
    } on MissingPluginException {
      // Notifications are available on the Android app build.
    } catch (_) {
      // Notification failures should not interrupt message delivery.
    }
  }
}
