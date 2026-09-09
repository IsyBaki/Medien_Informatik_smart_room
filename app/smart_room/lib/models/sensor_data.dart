import 'package:cloud_firestore/cloud_firestore.dart';

/// Eine einzelne Sensor-Messung (Temperatur, Luftfeuchtigkeit, Luftqualität, Personen).
class SensorData {
  final double temperature;
  final double humidity;
  final int persons;
  final String airQuality;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.persons,
    required this.airQuality,
    required this.timestamp,
  });

  // Nachricht vom ESP32 über WebSocket (kein Zeitstempel im Payload -> Empfangszeit).
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      persons: (json['persons'] as num?)?.toInt() ?? 0,
      airQuality: json['airQuality'] as String? ?? 'Unbekannt',
      timestamp: DateTime.now(),
    );
  }

  /// Erstellt eine Messung aus einem Firestore-Dokument.
  factory SensorData.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return SensorData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0,
      persons: (map['persons'] as num?)?.toInt() ?? 0,
      airQuality: map['airQuality'] as String? ?? 'Unbekannt',
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  /// Wandelt die Messung in ein Firestore-Format um.
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'persons': persons,
      'airQuality': airQuality,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
