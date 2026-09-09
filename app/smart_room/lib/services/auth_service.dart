import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_event.dart';
import 'database_service.dart';

/// Dünner Wrapper um FirebaseAuth: Registrierung, Login, Logout.
/// Wandelt technische FirebaseAuthException in deutsche Fehlertexte um.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  /// Meldet, ob und mit welchem Benutzer man gerade angemeldet ist.
  /// Darauf hört der AuthGate, um zwischen Welcome-Seite und Smart Room zu wechseln.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Der aktuell angemeldete Benutzer (null, wenn niemand angemeldet ist).
  User? get currentUser => _auth.currentUser;

  /// Legt ein neues Konto an und erstellt gleichzeitig das Firestore-Profil.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        await _databaseService.createUserProfile(uid: uid, email: email);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Meldet an und protokolliert dafür ein Login-Ereignis in der History.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _databaseService.logEvent(
        RoomEventType.login,
        byUid: credential.user?.uid,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Meldet den aktuellen Benutzer ab.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Wandelt Firebase-Fehlercodes in verständliche deutsche Meldungen um.
  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Diese E-Mail-Adresse wird bereits verwendet.';
      case 'invalid-email':
        return 'Die E-Mail-Adresse ist ungültig.';
      case 'weak-password':
        return 'Das Passwort ist zu schwach (mindestens 6 Zeichen).';
      case 'user-not-found':
        return 'Es existiert kein Konto mit dieser E-Mail-Adresse.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-Mail-Adresse oder Passwort ist falsch.';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte versuche es später erneut.';
      default:
        return 'Ein Fehler ist aufgetreten: ${e.message ?? e.code}';
    }
  }
}
