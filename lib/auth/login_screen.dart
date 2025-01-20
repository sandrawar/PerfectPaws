import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        context.go('/');
      }
    } on FirebaseAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.loginError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(197, 174, 174, 1),
        title: Text(
          localizations.logIn,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: localizations.email,
                labelStyle: const TextStyle(color: Colors.white),
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.password,
                  labelStyle: const TextStyle(color: Colors.white),
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text(localizations.logIn),
            ),
            TextButton(
              onPressed: () {
                context.go('/register');
              },
              child: Text(localizations.newUser,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
