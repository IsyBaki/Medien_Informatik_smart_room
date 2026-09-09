import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/auth_gate.dart';


/// Startpunkt der App: verbindet zuerst Firebase, dann startet die App.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartRoomApp());
}

/// Wurzel-Widget der App: legt Theme fest und startet mit dem AuthGate.
class SmartRoomApp extends StatelessWidget {
  const SmartRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Room',
      theme: ThemeData.dark(),
      home: const AuthGate(),
    );
  }
}



