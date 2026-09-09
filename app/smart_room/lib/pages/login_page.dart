import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_page.dart';

/// Seite zum Einloggen mit E-Mail + Passwort.
class LoginPage extends StatefulWidget {
  // Optionale Meldung, z.B. nach erfolgreicher Registrierung.
  final String? message;

  const LoginPage({super.key, this.message});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authService = AuthService();

  bool isLoading = false;

  /// Zeigt eine übergebene Meldung (z.B. nach der Registrierung) einmalig an.
  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showError(widget.message!);
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Prüft die Eingaben, meldet an und schließt bei Erfolg auf den Smart Room.
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Bitte E-Mail und Passwort eingeben.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.login(email: email, password: password);
      // AuthGate zeigt jetzt intern schon den Smart Room -- wir müssen die
      // Login-Seite (und ggf. Register-Seite) nur noch vom Stack entfernen,
      // damit man sie auch sofort sieht statt erst nach "Zurück".
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Zeigt eine Fehler- oder Infomeldung als SnackBar an.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Baut das Formular: E-Mail, Passwort, Einloggen-Button, Link zur Registrierung.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einloggen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Einloggen'),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
              child: const Text('Noch kein Konto? Jetzt registrieren'),
            ),
          ],
        ),
      ),
    );
  }
}
