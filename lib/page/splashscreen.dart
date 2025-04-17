import 'package:alpha_generations/HomePage.dart';
import 'package:alpha_generations/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  double _logoOpacity = 0.0;
  double _textOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startSplashAnimation();
  }

  Future<void> _startSplashAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _logoOpacity = 1.0);

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _textOpacity = 1.0);

    await Future.delayed(const Duration(seconds: 3));
    _checkAuth();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage(loginMessage: '')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _logoOpacity,
                child: Image.asset("images/logo.jpg", width: 180),
              ),
              const SizedBox(height: 20),
              AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _textOpacity,
                child: const Text(
                  "Welcome to Alpha Generations",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
