import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'smart_room_page.dart';
import 'welcome_page.dart';

// leitet je nach Anmeldestatus zur Welcome-Seite oder zum Smart Room weiter
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const SmartRoomPage();
        }

        return const WelcomePage();
      },
    );
  }
}
