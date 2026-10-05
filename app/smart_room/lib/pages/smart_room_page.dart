import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/room_event.dart';
import '../models/sensor_data.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/esp32_service.dart';
import '../widgets/info_card.dart';
import '../widgets/control_row.dart';
import '../styles/app_styles.dart';
import 'history_page.dart';

// Hauptseite nach dem Login: zeigt Sensorwerte und steuert Licht/Lüfter/Party.
class SmartRoomPage extends StatefulWidget {
  const SmartRoomPage({super.key});

  @override
  State<SmartRoomPage> createState() => _SmartRoomPageState();
}

class _SmartRoomPageState extends State<SmartRoomPage> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _esp32Service = Esp32Service();

  // aktuelle Uhrzeit (vom Handy, nicht vom ESP32) -- wird jede Sekunde
  // aktualisiert, siehe updateClock(). Angezeigt in buildTimeBox().
  String currentTime = '--:--:--';
  Timer? _clockTimer;

  bool _esp32Connected = false;

  // echter Lüfter-Status, wie ihn der ESP32 gerade meldet (unabhängig davon,
  // ob er automatisch durch die Luftqualität oder manuell per App geschaltet
  // wurde). null = noch keine Meldung vom ESP32 erhalten -- dann wird
  // ersatzweise der zuletzt per App gesendete Wert aus Firestore angezeigt.
  bool? _liveFanOn;

  StreamSubscription<SensorData>? _sensorSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();

    updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => updateClock());

    _databaseService.ensureRoomDefaults();

    // Sobald der ESP32 Daten schickt, landen sie in Firestore und erscheinen
    // dadurch automatisch im StreamBuilder unten (buildInformationGrid).
    // Zusätzlich merken wir uns den echten Lüfter-Status, den der ESP32
    // mitschickt, damit die App auch automatische Schaltungen (z.B. durch
    // schlechte Luftqualität) sofort korrekt anzeigt -- nicht nur Schaltungen
    // über den App-Button.
    _sensorSubscription = _esp32Service.sensorDataStream.listen((data) {
      _databaseService.saveSensorReading(data);
      if (data.fanOn != null && mounted) {
        setState(() => _liveFanOn = data.fanOn);
      }
    });
    _connectionSubscription = _esp32Service.isConnected.listen((connected) {
      if (mounted) setState(() => _esp32Connected = connected);
    });

    // Umgestellt auf den iPhone-Hotspot (vorher Heim-WLAN 192.168.0.10).
    // IP kommt aus dem Serial Monitor ("Verbunden! IP-Adresse: ..."). Falls
    // der Hotspot neu verbindet, kann sich diese IP wieder aendern -- dann
    // hier einfach die neue Adresse eintragen.

    // wlan zuhasue
    _esp32Service.connect('192.168.0.9');

    // IP adresse hier eingeben
    //  handy: IP-Adresse: 172.20.10.2
    // Maxs Handy
    //_esp32Service.connect('10.122.68.32');

    // hotspot iphone
  }

  void updateClock() {
    final now = DateTime.now();

    setState(() {
      currentTime =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();
    _esp32Service.dispose();
    super.dispose();
  }

  // speichert den Status in Firestore, protokolliert das Ereignis und
  // schickt den Befehl zusätzlich an den ESP32 (falls verbunden)
  void toggleDevice(String device, bool value) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _databaseService.updateDeviceStatus(
      device: device,
      state: value,
      updatedBy: uid,
    );
    _databaseService.logEvent(_eventTypeFor(device, value), byUid: uid);
    _esp32Service.sendCommand(device, value);
  }

  RoomEventType _eventTypeFor(String device, bool value) {
    switch (device) {
      case AppConstants.deviceLight:
        return value ? RoomEventType.lightOn : RoomEventType.lightOff;
      case AppConstants.deviceFan:
        return value ? RoomEventType.fanOn : RoomEventType.fanOff;
      case AppConstants.deviceParty:
      default:
        return value ? RoomEventType.partyOn : RoomEventType.partyOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),

      appBar: AppBar(
        title: const Text('🏠 Smart Room'),
        centerTitle: true,
        backgroundColor: const Color(0xff1e293b),
      ),

      drawer: buildDrawer(),

      body: StreamBuilder<Map<String, dynamic>>(
        stream: _databaseService.streamDeviceStatus(),
        builder: (context, statusSnapshot) {
          final status = statusSnapshot.data ?? {};
          final light = status[AppConstants.deviceLight] as bool? ?? false;
          // echter Lüfter-Status vom ESP32 hat Vorrang (zeigt auch automatische
          // Schaltungen durch die Luftqualität korrekt an). Solange noch keine
          // Meldung vom ESP32 da ist, wird der letzte per App gesendete Wert
          // aus Firestore als Ersatz angezeigt.
          final fan =
              _liveFanOn ?? (status[AppConstants.deviceFan] as bool? ?? false);
          final party = status[AppConstants.deviceParty] as bool? ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                buildInformationGrid(),

                const SizedBox(height: 25),

                buildTimeBox(),

                const SizedBox(height: 25),

                buildStatusBox(light: light, fan: fan, party: party),

                const SizedBox(height: 25),

                const Text(
                  'Steuerung',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ControlRow(
                  onText: '💡 Licht AN',
                  offText: 'Licht AUS',
                  isOn: light,
                  onPressed: () => toggleDevice(AppConstants.deviceLight, true),
                  offPressed: () => toggleDevice(AppConstants.deviceLight, false),
                ),

                ControlRow(
                  onText: '🌀 Lüfter AN',
                  offText: 'Lüfter AUS',
                  isOn: fan,
                  onPressed: () => toggleDevice(AppConstants.deviceFan, true),
                  offPressed: () => toggleDevice(AppConstants.deviceFan, false),
                ),

                ControlRow(
                  onText: '🎵 Party AN',
                  offText: 'Party AUS',
                  isOn: party,
                  onPressed: () => toggleDevice(AppConstants.deviceParty, true),
                  offPressed: () => toggleDevice(AppConstants.deviceParty, false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInformationGrid() {
    return StreamBuilder<SensorData?>(
      stream: _databaseService.streamLatestSensorData(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            InfoCard(
              title: '👥 Personen',
              value: data != null ? '${data.persons}' : '--',
            ),
            InfoCard(
              title: '🌡 Temperatur',
              value: data != null ? '${data.temperature}°C' : '--',
            ),
            InfoCard(
              title: '💨 Luftqualität',
              value: data?.airQuality ?? '--',
            ),
            InfoCard(
              title: '💧 Luftfeuchtigkeit',
              value: data != null ? '${data.humidity.toStringAsFixed(0)}%' : '--',
            ),
          ],
        );
      },
    );
  }

  // eigene Box, genauso breit und im gleichen Stil wie die Status-Box darunter
  Widget buildTimeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: boxStyle(),
      child: Column(
        children: [
          const Text(
            '🕒 Uhrzeit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBox({
    required bool light,
    required bool fan,
    required bool party,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: boxStyle(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              _esp32Badge(),
            ],
          ),

          const SizedBox(height: 15),

          Text('Licht: ${light ? "EIN" : "AUS"}'),
          Text('Lüfter: ${fan ? "EIN" : "AUS"}'),
          Text('Party: ${party ? "EIN" : "AUS"}'),
        ],
      ),
    );
  }

  // kleiner Punkt + Text: zeigt, ob gerade eine ESP32-Verbindung besteht
  Widget _esp32Badge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: _esp32Connected ? Colors.greenAccent : Colors.grey,
        ),
        const SizedBox(width: 5),
        Text(
          _esp32Connected ? 'ESP32 verbunden' : 'ESP32 nicht verbunden',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    // Anzeigename, falls bei der Registrierung angegeben -- sonst E-Mail
    final displayName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? '');

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Smart Room Menü',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(displayName, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Ausloggen'),
            onTap: () async {
              Navigator.pop(context);
              await _authService.logout();
              // AuthGate leitet danach automatisch zur Welcome-Seite weiter.
            },
          ),
        ],
      ),
    );
  }
}
