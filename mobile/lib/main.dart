import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/users_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/resender_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChatVerseApp());
}

class ChatVerseApp extends StatelessWidget {
  const ChatVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'ReSender',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF7A00),
            secondary: Color(0xFF2C2C2C),
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF2C2C2C)),
            titleTextStyle: TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: Border(
              bottom: BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
          ),
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.white,
            elevation: 10,
            shadowColor: Color(0x22000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFF0F1F3)),
            ),
            textStyle: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            elevation: 12,
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF2C2C2C),
            contentTextStyle: TextStyle(color: Colors.white),
            elevation: 4,
            behavior: SnackBarBehavior.floating,
          ),
          useMaterial3: true,
        ),
        scrollBehavior:
            const MaterialScrollBehavior().copyWith(overscroll: false),
        home: const _SessionGate(),
      ),
    );
  }
}

/// Checks saved session on app start and routes accordingly.
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool _startupComplete = false;
  bool _lastAuthState = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    if (status == AuthStatus.authenticated) {
      _startupComplete = true;
      _lastAuthState = true;
      return const HomeScreen();
    }
    if (status == AuthStatus.unauthenticated) {
      _startupComplete = true;
      _lastAuthState = false;
      return const LoginScreen();
    }
    if (_startupComplete) {
      return _lastAuthState ? const HomeScreen() : const LoginScreen();
    }
    return const Scaffold(
      backgroundColor: Color(0xFFFFF9F4),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ReSender',
              style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ResenderLoader(showLabel: true, scale: 1.15),
          ],
        ),
      ),
    );
  }
}
