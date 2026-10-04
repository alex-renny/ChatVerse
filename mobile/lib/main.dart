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
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    await context.read<AuthProvider>().checkSession();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_rounded, size: 72, color: Color(0xFFFF7A00)),
            SizedBox(height: 20),
            Text(
              'ReSender',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Color(0xFFFF7A00),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
