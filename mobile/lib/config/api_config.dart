/// Central API configuration for ChatVerse mobile.
/// Change [baseUrl] to your deployed server URL for production builds.
class ApiConfig {
  ApiConfig._();

  /// The base URL of the ChatVerse backend server.
  /// For local development: "http://10.0.2.2:5000" (Android emulator → localhost)
  /// For production: "https://your-backend.onrender.com" (or wherever it's hosted)
  static const String baseUrl = 'https://chatverse-api.onrender.com';

  // ---------- REST endpoints ----------
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';

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

  // ---------- Socket ----------
  static String get socketUrl => baseUrl;
}
