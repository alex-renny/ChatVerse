/// Central API configuration for ChatVerse mobile.
/// Override with --dart-define=API_BASE_URL=http://10.0.2.2:5000 for emulator.
class ApiConfig {
  ApiConfig._();

  /// The base URL of the ChatVerse backend server.
  /// For local development: "http://10.0.2.2:5000" (Android emulator → localhost)
  /// For production: "https://your-backend.onrender.com" (or wherever it's hosted)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://chatverse-server-eoma.onrender.com',
  );

  // ---------- REST endpoints ----------
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';
  static String get authSession => '$baseUrl/api/auth/session';
  static String get adminOverview => '$baseUrl/api/admin/overview';

  static String get users => '$baseUrl/api/users';
  static String get conversations => '$baseUrl/api/users/conversations';
  static String messages(String receiverId) =>
      '$baseUrl/api/messages/$receiverId';
  static String sendMessage() => '$baseUrl/api/messages';
  static String deleteMessage(String messageId) =>
      '$baseUrl/api/messages/$messageId';
  static String markSeen(String senderId) =>
      '$baseUrl/api/messages/seen/$senderId';
  static String reactMessage(String messageId) =>
      '$baseUrl/api/messages/react/$messageId';
  static String pinMessage(String messageId) =>
      '$baseUrl/api/messages/pin/$messageId';
  static String unpinMessage(String messageId) =>
      '$baseUrl/api/messages/unpin/$messageId';
  static String clearChat(String receiverId) =>
      '$baseUrl/api/messages/clear/$receiverId';

  static String get profilePicture => '$baseUrl/api/profile/picture';
  static String get updateProfile => '$baseUrl/api/profile/update';

  static String pinChat(String userId) => '$baseUrl/api/users/$userId/pin';
  static String chatBackground(String userId) =>
      '$baseUrl/api/users/$userId/background';
  static String get chatPassword => '$baseUrl/api/profile/chat-password';
  static String chatPasswordEnabled(String userId) =>
      '$baseUrl/api/users/$userId/chat-password-enabled';
  static String get verifyChatPassword =>
      '$baseUrl/api/users/verify-chat-password';

  // ---------- Socket ----------
  static String get socketUrl => baseUrl;
}
