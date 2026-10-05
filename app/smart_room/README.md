# Smart Room

Ein Raum mit ESP32, Sensoren und Aktoren, gesteuert über eine Flutter-App.
Anmeldung und Daten laufen über Firebase (Authentication + Firestore), die
Verbindung zum ESP32 läuft über WebSocket.

## Aufbau

- **App (Flutter)**: Anmeldung, Steuerung von Licht/Lüfter/Party, Anzeige der
  Sensorwerte, History-Seite (`lib/`, siehe Unterordner `pages/`, `services/`,
  `models/`, `widgets/`, `utils/`).
- **ESP32 (Firmware)**: `esp32/smart_room_esp32.ino` -- verbindet sich mit dem
  WLAN, öffnet einen WebSocket-Server, sendet Sensordaten und schaltet
  Licht/Lüfter/Party. Echte Sensoren sind noch auskommentiert, aktuell werden
  simulierte Werte gesendet, da noch keine Hardware dauerhaft angeschlossen ist.
- **Firebase**: speichert Benutzer, Gerätestatus, Sensor-Messwerte und
  Ereignisse (`firebase.json`, `firestore.rules`, automatisch erzeugte
  `firebase_options.dart` -- nicht von Hand ändern).

## Datenbank-Struktur (Firestore)

```
users/{uid}                Profil des Benutzers
smart_room/status          Aktueller Zustand (Licht, Lüfter, Party)
smart_room/status/history  Sensor-Messwerte mit Zeitstempel
smart_room/status/events   Ereignisse (Schaltungen, Login) mit Zeitstempel
```

## Projekt starten

```bash
flutter pub get
flutter run
```

```
=================================== sinnvolle befehle =============================
1) Zum Projekt wechseln
cd ~/smart_room

2) Emulator in Android Studio starten
 Device Manager → Emulator starten

3) Prüfen, ob der Emulator erkannt wurde
flutter devices

4)  Projekt vorbereiten
flutter clean
flutter pub get

5)  App starten
flutter run -d emulator-5554

6) App beenden
Ctrl + C

r  → Hot Reload
R  → Hot Restart
q  → App beenden



# Daten für test user:
username: test
email: test@test.com    
passwort: test12345
```
