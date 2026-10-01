import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/users_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

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
        title: 'ChatVerse',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A1A),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF7C3AED),
            secondary: const Color(0xFF3B82F6),
            surface: const Color(0xFF1A1A2E),
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F0F23),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white70),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF1A1A2E),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
          useMaterial3: true,
        ),
        home: const _Splash(),
      ),
    );
  }
}

/// Checks saved session on app start and routes accordingly.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    await context.read<AuthProvider>().checkSession();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_rounded,
                size: 72, color: Color(0xFF7C3AED)),
            SizedBox(height: 20),
            Text(
              'ChatVerse',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Color(0xFF7C3AED),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
