import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';
import '../models/sensor_data.dart';

/// WebSocket-Client für die Verbindung zum ESP32.
///
/// Solange keine echte Hardware verbunden ist, dürfen Verbindungsfehler
/// die App nicht zum Absturz bringen -- deshalb werden alle Fehler
/// abgefangen und nur über [isConnected] / [errorStream] gemeldet.
class Esp32Service {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  /// Sensordaten, die gerade vom ESP32 hereinkommen.
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  /// Meldet, ob gerade eine WebSocket-Verbindung zum ESP32 besteht.
  Stream<bool> get isConnected => _connectionController.stream;

  bool _connected = false;

  /// Baut die WebSocket-Verbindung zur angegebenen IP-Adresse auf.
  Future<void> connect(String ip, {int port = AppConstants.esp32DefaultPort}) async {
    await disconnect();

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ip:$port'));
      await _channel!.ready;

      _connected = true;
      _connectionController.add(true);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  /// Verarbeitet eine eingehende JSON-Nachricht vom ESP32.
  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      _sensorDataController.add(SensorData.fromJson(json));
    } catch (_) {
      // Ungültige Nachricht vom ESP32 ignorieren.
    }
  }

  /// Setzt den Verbindungsstatus auf "getrennt" und meldet das über [isConnected].
  void _handleDisconnect() {
    if (_connected) {
      _connected = false;
      _connectionController.add(false);
    }
  }

  /// Sendet einen Steuerbefehl (z.B. Licht an) an den ESP32.
  void sendCommand(String device, bool state) {
    if (!_connected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'device': device, 'state': state}));
    } catch (_) {
      _handleDisconnect();
    }
  }

  /// Trennt die WebSocket-Verbindung.
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _handleDisconnect();
  }

  /// Räumt auf, wenn der Service nicht mehr gebraucht wird (Streams schließen).
  void dispose() {
    disconnect();
    _sensorDataController.close();
    _connectionController.close();
  }
}
