# Smart Room

Projekt: Ein Raum mit ESP32, Sensoren und Aktoren, gesteuert über eine Flutter-App.
Anmeldung und Daten laufen über Firebase (Authentication + Firestore), die Verbindung
zum ESP32 läuft über WebSocket.

## Aufbau

- **App (Flutter)**: Anmeldung, Steuerung von Licht/Lüfter/Party, Anzeige der Sensorwerte, History-Seite.
- **ESP32 (Firmware)**: liest Sensoren aus, schaltet Licht/Lüfter, schickt/empfängt Daten per WebSocket.
- **Firebase**: speichert Benutzer, Gerätestatus, Sensor-Messwerte und Ereignisse.

## Ordnerstruktur (`lib/`)

```
lib/
├── main.dart              Startpunkt: initialisiert Firebase, startet die App
├── firebase_options.dart  Automatisch von FlutterFire erzeugt (Firebase-Zugangsdaten)
│
├── models/                Datenklassen (nur Struktur, keine Logik)
│   ├── user_model.dart     Benutzerprofil (E-Mail, Einstellungen)
│   ├── sensor_data.dart    Eine Messung (Temperatur, Luftfeuchtigkeit, Luftqualität, Personen)
│   └── room_event.dart     Ein Ereignis (Licht an/aus, Login, ...)
│
├── services/              Zugriff auf Firebase und den ESP32
│   ├── auth_service.dart     Registrieren, Einloggen, Ausloggen
│   ├── database_service.dart Lesen/Schreiben in Firestore
│   └── esp32_service.dart    WebSocket-Verbindung zum ESP32
│
├── pages/                  Bildschirme der App
│   ├── welcome_page.dart      Startseite (nicht angemeldet)
│   ├── auth_gate.dart         Entscheidet: Welcome-Seite oder Smart Room
│   ├── login_page.dart        Einloggen
│   ├── register_page.dart     Registrieren
│   ├── smart_room_page.dart   Hauptseite: Sensorwerte + Steuerung
│   └── history_page.dart      Verlauf: Sensoren, Ereignisse, Hinweise
│
├── widgets/                Wiederverwendbare UI-Bausteine
│   ├── info_card.dart        Kachel für einen Sensorwert
│   └── control_row.dart      AN/AUS-Buttons für ein Gerät
│
├── utils/                   Hilfsfunktionen (keine Firebase-Zugriffe)
│   ├── date_range.dart        Zeiträume (Heute, Gestern, ...)
│   └── room_stats.dart        Berechnet Durchschnitt, Hinweise, Empfehlungen
│
└── constants/
    └── app_constants.dart    Feste Namen (Gerätenamen, Firestore-Collections)
```

## ESP32 (`esp32/`)

- `smart_room_esp32.ino` — Firmware: verbindet sich mit dem WLAN, öffnet einen
  WebSocket-Server, sendet Sensordaten und schaltet Licht/Lüfter/Party.
  Echte Sensoren sind noch auskommentiert (aktuell simulierte Werte, da noch
  keine Hardware angeschlossen ist).

## Firebase

- `firebase.json`, `firebase_options.dart`, `google-services.json` — Verbindung
  der App zum Firebase-Projekt (automatisch erzeugt, nicht von Hand ändern).
- `firestore.rules` — Regeln: jeder Benutzer sieht nur sein eigenes Profil,
  Raumdaten sind für alle angemeldeten Benutzer sichtbar.

## Datenbank-Struktur (Firestore)

```
users/{uid}                      Profil des Benutzers
smart_room/status                Aktueller Zustand (Licht, Lüfter, Party)
smart_room/status/history        Sensor-Messwerte mit Zeitstempel
smart_room/status/events         Ereignisse (Schaltungen, Login) mit Zeitstempel
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
