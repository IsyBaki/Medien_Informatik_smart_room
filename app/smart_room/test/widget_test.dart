import 'package:flutter_test/flutter_test.dart';

import 'package:smart_room/models/sensor_data.dart';

void main() {
  test('SensorData.fromJson parst eine ESP32-Nachricht', () {
    final data = SensorData.fromJson({
      'temperature': 22.5,
      'humidity': 45.0,
      'persons': 2,
      'airQuality': 'Gut',
    });

    expect(data.temperature, 22.5);
    expect(data.humidity, 45.0);
    expect(data.persons, 2);
    expect(data.airQuality, 'Gut');
  });

  test('SensorData.toMap/fromMap sind konsistent', () {
    final original = SensorData(
      temperature: 21.0,
      humidity: 50.0,
      persons: 1,
      airQuality: 'Mittel',
      timestamp: DateTime(2026, 1, 1),
    );

    final restored = SensorData.fromMap(original.toMap());

    expect(restored.temperature, original.temperature);
    expect(restored.humidity, original.humidity);
    expect(restored.persons, original.persons);
    expect(restored.airQuality, original.airQuality);
  });
}
