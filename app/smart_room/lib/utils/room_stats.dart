import '../models/room_event.dart';
import '../models/sensor_data.dart';

// Ampel-Einstufung für Benachrichtigungen/Empfehlungen -- steuert die
// farbige Anzeige (grün/gelb/rot) im "Hinweise"-Tab.
enum Severity { ok, warning, critical }

class Hint {
  final String text;
  final Severity severity;

  const Hint(this.text, this.severity);
}

// Zusammengefasste Kennzahlen für einen Zeitraum -- Basis für die
// Zusammenfassung auf dem Sensoren-Tab sowie die Benachrichtigungen/
// Empfehlungen im Hinweise-Tab der History-Seite.
class RoomStats {
  final int readingCount;
  final double avgTemperature;
  final double maxTemperature;
  final double minTemperature;
  final double avgHumidity;
  final int goodAirCount;
  final int badAirCount;
  final int maxPersons;
  final double avgPersons;
  final Duration lightOnDuration;
  final Duration fanOnDuration;
  final int lightToggleCount;
  final int fanToggleCount;

  RoomStats({
    required this.readingCount,
    required this.avgTemperature,
    required this.maxTemperature,
    required this.minTemperature,
    required this.avgHumidity,
    required this.goodAirCount,
    required this.badAirCount,
    required this.maxPersons,
    required this.avgPersons,
    required this.lightOnDuration,
    required this.fanOnDuration,
    required this.lightToggleCount,
    required this.fanToggleCount,
  });

  // "Gut"/"Schlecht" je nachdem, was im Zeitraum öfter vorkam -- "--" ohne Daten
  String get averageAirQualityLabel {
    if (goodAirCount == 0 && badAirCount == 0) return '--';
    return goodAirCount >= badAirCount ? 'Gut' : 'Schlecht';
  }

  factory RoomStats.compute({
    required List<SensorData> readings,
    required List<RoomEvent> events,
    required DateTime rangeStart,
    DateTime? rangeEnd,
  }) {
    final end = rangeEnd ?? DateTime.now();

    double sumTemp = 0;
    double maxTemp = 0;
    double minTemp = 0;
    double sumHumidity = 0;
    int good = 0;
    int bad = 0;
    int maxPersons = 0;
    int sumPersons = 0;

    for (var i = 0; i < readings.length; i++) {
      final r = readings[i];
      sumTemp += r.temperature;
      sumHumidity += r.humidity;
      sumPersons += r.persons;
      if (i == 0 || r.temperature > maxTemp) maxTemp = r.temperature;
      if (i == 0 || r.temperature < minTemp) minTemp = r.temperature;
      if (r.persons > maxPersons) maxPersons = r.persons;

      final quality = r.airQuality.toLowerCase();
      if (quality.contains('gut')) {
        good++;
      } else if (quality.contains('schlecht')) {
        bad++;
      }
    }

    return RoomStats(
      readingCount: readings.length,
      avgTemperature: readings.isEmpty ? 0 : sumTemp / readings.length,
      maxTemperature: maxTemp,
      minTemperature: minTemp,
      avgHumidity: readings.isEmpty ? 0 : sumHumidity / readings.length,
      goodAirCount: good,
      badAirCount: bad,
      maxPersons: maxPersons,
      avgPersons: readings.isEmpty ? 0 : sumPersons / readings.length,
      lightOnDuration: _onDuration(
        events,
        RoomEventType.lightOn,
        RoomEventType.lightOff,
        end,
      ),
      fanOnDuration: _onDuration(
        events,
        RoomEventType.fanOn,
        RoomEventType.fanOff,
        end,
      ),
      lightToggleCount:
          events.where((e) => e.type == RoomEventType.lightOn).length,
      fanToggleCount: events.where((e) => e.type == RoomEventType.fanOn).length,
    );
  }

  // Summiert die Zeit zwischen "an"- und "aus"-Events. Ist das Gerät am Ende
  // des Zeitraums noch an (kein passendes "aus"-Event), zählt die Zeit bis
  // rangeEnd.
  static Duration _onDuration(
    List<RoomEvent> events,
    RoomEventType onType,
    RoomEventType offType,
    DateTime rangeEnd,
  ) {
    final relevant = events.where((e) => e.type == onType || e.type == offType).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    var total = Duration.zero;
    DateTime? onSince;

    for (final e in relevant) {
      if (e.type == onType) {
        onSince ??= e.timestamp;
      } else if (onSince != null) {
        total += e.timestamp.difference(onSince);
        onSince = null;
      }
    }

    if (onSince != null) {
      total += rangeEnd.difference(onSince);
    }

    return total;
  }

  List<Hint> notifications() {
    final list = <Hint>[];
    final totalAir = goodAirCount + badAirCount;

    if (readingCount == 0) {
      return [const Hint('Keine Messwerte im gewählten Zeitraum.', Severity.ok)];
    }

    if (maxTemperature > 28) {
      list.add(Hint(
        'Die Temperatur überschritt ${maxTemperature.toStringAsFixed(1)}°C.',
        Severity.critical,
      ));
    } else if (maxTemperature > 26) {
      list.add(Hint(
        'Die Temperatur war zeitweise erhöht (max. ${maxTemperature.toStringAsFixed(1)}°C).',
        Severity.warning,
      ));
    }

    if (totalAir > 0 && badAirCount / totalAir > 0.5) {
      list.add(Hint(
        'Die Luftqualität war in $badAirCount von $totalAir Messungen schlecht.',
        Severity.critical,
      ));
    } else if (totalAir > 0 && badAirCount / totalAir > 0.2) {
      list.add(Hint(
        'Die Luftqualität war zeitweise schlecht ($badAirCount von $totalAir Messungen).',
        Severity.warning,
      ));
    }

    if (fanOnDuration > const Duration(hours: 6)) {
      list.add(const Hint('Der Lüfter war ungewöhnlich lange eingeschaltet.', Severity.warning));
    }

    if (maxPersons == 0) {
      list.add(const Hint('Der Raum war im gewählten Zeitraum durchgehend unbelegt.', Severity.ok));
    }

    if (list.isEmpty) {
      list.add(const Hint('Keine ungewöhnlichen Ereignisse erkannt.', Severity.ok));
      list.add(const Hint('Alle Sensoren arbeiten normal.', Severity.ok));
    }

    return list;
  }

  List<Hint> recommendations() {
    final list = <Hint>[];
    final totalAir = goodAirCount + badAirCount;

    if (totalAir > 0 && badAirCount / totalAir > 0.3) {
      list.add(const Hint('Bitte den Raum lüften.', Severity.warning));
      if (fanOnDuration < const Duration(hours: 1)) {
        list.add(const Hint('Lüfter einschalten.', Severity.warning));
      }
    }

    if (maxTemperature > 26 && fanOnDuration < const Duration(hours: 1)) {
      list.add(const Hint('Temperatur reduzieren oder Lüfter öfter einschalten.', Severity.warning));
    }

    if (lightOnDuration > const Duration(hours: 4) && maxPersons == 0) {
      list.add(const Hint('Licht ausschalten, wenn niemand im Raum ist.', Severity.warning));
    }

    if (list.isEmpty) {
      list.add(const Hint('Die Raumtemperatur liegt im optimalen Bereich.', Severity.ok));
      list.add(const Hint('Die Luftqualität ist aktuell gut.', Severity.ok));
      list.add(const Hint('Keine Maßnahmen erforderlich.', Severity.ok));
    }

    return list;
  }

  // höchste Einstufung aus einer Liste von Hinweisen, für den
  // zusammenfassenden Status ("Alles ok"/"Warnung"/"Kritisch")
  static Severity overallSeverity(List<Hint> hints) {
    if (hints.any((h) => h.severity == Severity.critical)) return Severity.critical;
    if (hints.any((h) => h.severity == Severity.warning)) return Severity.warning;
    return Severity.ok;
  }
}
