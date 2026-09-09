import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/room_event.dart';
import '../models/sensor_data.dart';
import '../services/database_service.dart';
import '../styles/app_styles.dart';
import '../utils/date_range.dart';
import '../utils/room_stats.dart';

/// Zeigt vergangene Sensordaten und Ereignisse -- 3 Tabs:
/// Sensoren (Diagramm + Zusammenfassung + Tabelle), Ereignisse (Liste mit
/// Filter), Hinweise (Benachrichtigungen + Empfehlungen mit Ampel-Status).
/// Ein Zeitraum-Filter oben gilt für alle drei Tabs.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final _databaseService = DatabaseService();
  late final TabController _tabController;
  HistoryRange _range = HistoryRange.today;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Baut das Grundgerüst: Tabs oben, Zeitraum-Auswahl, darunter der aktive Tab.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xff1e293b),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sensoren'),
            Tab(text: 'Ereignisse'),
            Tab(text: 'Hinweise'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildRangeSelector(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SensorsTab(databaseService: _databaseService, range: _range),
                _EventsTab(databaseService: _databaseService, range: _range),
                _HintsTab(databaseService: _databaseService, range: _range),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown zur Auswahl des Zeitraums, gilt für alle drei Tabs.
  Widget _buildRangeSelector() {
    return Row(
      children: [
        const Text('Zeitraum:'),
        const SizedBox(width: 10),
        DropdownButton<HistoryRange>(
          value: _range,
          dropdownColor: const Color(0xff1e293b),
          items: HistoryRange.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _range = value);
          },
        ),
      ],
    );
  }
}

// Gemeinsames Zeitstempel-Format für alle Tabs.
String _formatTimestamp(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}.${two(dt.month)}. ${two(dt.hour)}:${two(dt.minute)}';
}

// --- Tab 1: Sensoren ---------------------------------------------------------

// Welcher Messwert gerade im Diagramm ausgewählt ist.
enum _SensorMetric { temperature, humidity, persons }

extension on _SensorMetric {
  /// Anzeigetext für die Auswahl-Chips.
  String get label {
    switch (this) {
      case _SensorMetric.temperature:
        return 'Temperatur';
      case _SensorMetric.humidity:
        return 'Luftfeuchtigkeit';
      case _SensorMetric.persons:
        return 'Personenanzahl';
    }
  }

  /// Linienfarbe im Diagramm, je nach ausgewähltem Messwert.
  Color get color {
    switch (this) {
      case _SensorMetric.temperature:
        return Colors.orangeAccent;
      case _SensorMetric.humidity:
        return Colors.lightBlueAccent;
      case _SensorMetric.persons:
        return Colors.purpleAccent;
    }
  }

  /// Holt den passenden Zahlenwert aus einer Messung.
  double valueOf(SensorData d) {
    switch (this) {
      case _SensorMetric.temperature:
        return d.temperature;
      case _SensorMetric.humidity:
        return d.humidity;
      case _SensorMetric.persons:
        return d.persons.toDouble();
    }
  }
}

/// Tab "Sensoren": Zusammenfassung, Diagramm und Tabelle der Messwerte.
class _SensorsTab extends StatefulWidget {
  final DatabaseService databaseService;
  final HistoryRange range;

  const _SensorsTab({required this.databaseService, required this.range});

  @override
  State<_SensorsTab> createState() => _SensorsTabState();
}

class _SensorsTabState extends State<_SensorsTab> {
  _SensorMetric _metric = _SensorMetric.temperature;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SensorData>>(
      stream: widget.databaseService.streamSensorHistory(widget.range),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = snapshot.data!;
        if (readings.isEmpty) {
          return const _EmptyState(
            text: 'Für den ausgewählten Zeitraum sind noch keine Messwerte vorhanden.',
          );
        }

        // Gerätezeiten (events) werden hier nicht gebraucht -- die stehen im
        // Hinweise-Tab, wo Sensor- und Ereignisdaten zusammen ausgewertet werden.
        final stats = RoomStats.compute(
          readings: readings,
          events: const [],
          rangeStart: widget.range.from,
          rangeEnd: widget.range.to,
        );

        // Neueste zuerst, auf 30 Zeilen begrenzt (Performance bei "Gesamt").
        final recentReadings = readings.reversed.take(30).toList();

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _summaryCard(stats),
            const SizedBox(height: 20),
            _metricPicker(),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: boxStyle(),
              child: LineChart(_chartData(readings)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sensorwerte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (final reading in recentReadings) _readingRow(reading),
            const SizedBox(height: 6),
            Text(
              'Letzte Messung: ${_formatTimestamp(readings.last.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        );
      },
    );
  }

  /// Auswahl-Chips: legen fest, welcher Messwert im Diagramm gezeigt wird.
  Widget _metricPicker() {
    return Wrap(
      spacing: 8,
      children: _SensorMetric.values.map((metric) {
        return ChoiceChip(
          label: Text(metric.label),
          selected: metric == _metric,
          onSelected: (_) => setState(() => _metric = metric),
        );
      }).toList(),
    );
  }

  /// Baut die Diagramm-Daten für den aktuell ausgewählten Messwert.
  LineChartData _chartData(List<SensorData> readings) {
    final spots = [
      for (var i = 0; i < readings.length; i++)
        FlSpot(i.toDouble(), _metric.valueOf(readings[i])),
    ];

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 34),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _metric.color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _metric.color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  /// Zeigt die Zusammenfassung (Ø/Max/Min-Werte) für den gewählten Zeitraum.
  Widget _summaryCard(RoomStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: boxStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zusammenfassung',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _summaryRow('Durchschnittstemperatur', '${stats.avgTemperature.toStringAsFixed(1)}°C'),
          _summaryRow('Höchste Temperatur', '${stats.maxTemperature.toStringAsFixed(1)}°C'),
          _summaryRow('Niedrigste Temperatur', '${stats.minTemperature.toStringAsFixed(1)}°C'),
          _summaryRow('Ø Luftfeuchtigkeit', '${stats.avgHumidity.toStringAsFixed(0)}%'),
          _summaryRow('Ø Luftqualität', stats.averageAirQualityLabel),
          _summaryRow('Max. Personen', '${stats.maxPersons}'),
          _summaryRow('Ø Personen', stats.avgPersons.toStringAsFixed(1)),
          _summaryRow('Messungen', '${stats.readingCount}'),
        ],
      ),
    );
  }

  /// Eine Zeile in der Zusammenfassung: Bezeichnung links, Wert rechts.
  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Eine Zeile in der Sensorwerte-Tabelle: Zeitstempel + alle Messwerte.
  Widget _readingRow(SensorData r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: boxStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTimestamp(r.timestamp),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            '${r.temperature.toStringAsFixed(1)}°C · ${r.humidity.toStringAsFixed(0)}% · ${r.airQuality} · ${r.persons} Pers.',
          ),
        ],
      ),
    );
  }
}

// --- Tab 2: Ereignisse -------------------------------------------------------

/// Tab "Ereignisse": Liste aller Schaltungen/Logins mit Filter-Chips.
class _EventsTab extends StatefulWidget {
  final DatabaseService databaseService;
  final HistoryRange range;

  const _EventsTab({required this.databaseService, required this.range});

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  RoomEventCategory? _filter; // null = "Alle"

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomEvent>>(
      stream: widget.databaseService.streamEvents(widget.range),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!
            .where((e) => _filter == null || e.type.category == _filter)
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _filterChips(),
            ),
            Expanded(
              child: events.isEmpty
                  ? const _EmptyState(text: 'Keine Ereignisse in diesem Zeitraum.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _eventTile(events[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Filter-Chips: "Alle" plus eine Chip pro Ereignis-Kategorie.
  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Alle', _filter == null, () => setState(() => _filter = null)),
          for (final category in RoomEventCategory.values)
            _chip(
              category.label,
              _filter == category,
              () => setState(() => _filter = category),
            ),
        ],
      ),
    );
  }

  /// Ein einzelner Filter-Chip.
  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  /// Eine Zeile in der Ereignisliste: Symbol, Titel + Beschreibung, Zeitstempel.
  Widget _eventTile(RoomEvent event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: boxStyle(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(event.type.icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  event.type.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(event.timestamp),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// --- Tab 3: Hinweise (Benachrichtigungen + Empfehlungen) --------------------

/// Tab "Hinweise": Ampel-Status, Benachrichtigungen und Empfehlungen.
class _HintsTab extends StatelessWidget {
  final DatabaseService databaseService;
  final HistoryRange range;

  const _HintsTab({required this.databaseService, required this.range});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SensorData>>(
      stream: databaseService.streamSensorHistory(range),
      builder: (context, sensorSnapshot) {
        return StreamBuilder<List<RoomEvent>>(
          stream: databaseService.streamEvents(range),
          builder: (context, eventSnapshot) {
            if (!sensorSnapshot.hasData || !eventSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = RoomStats.compute(
              readings: sensorSnapshot.data!,
              events: eventSnapshot.data!,
              rangeStart: range.from,
              rangeEnd: range.to,
            );

            final notifications = stats.notifications();
            final recommendations = stats.recommendations();
            final overall = RoomStats.overallSeverity(notifications);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _statusBadge(overall),
                const SizedBox(height: 20),
                _section('Benachrichtigungen', Icons.notifications, notifications),
                const SizedBox(height: 20),
                _section('Empfehlungen', Icons.lightbulb_outline, recommendations),
              ],
            );
          },
        );
      },
    );
  }

  /// Farbige Status-Zeile ganz oben (grün/gelb/rot je nach Gesamteinstufung).
  Widget _statusBadge(Severity severity) {
    late final Color color;
    late final String text;
    switch (severity) {
      case Severity.ok:
        color = Colors.greenAccent;
        text = 'Status: Alles in Ordnung';
        break;
      case Severity.warning:
        color = Colors.amberAccent;
        text = 'Status: Warnung';
        break;
      case Severity.critical:
        color = Colors.redAccent;
        text = 'Status: Kritisch';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: boxStyle(),
      child: Row(
        children: [
          Icon(Icons.circle, size: 14, color: color),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Eine Box mit Titel + Liste von Hinweisen (Benachrichtigungen oder Empfehlungen).
  Widget _section(String title, IconData icon, List<Hint> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: boxStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items) _hintRow(item),
        ],
      ),
    );
  }

  /// Eine Zeile mit farbigem Punkt (je nach Einstufung) und Hinweistext.
  Widget _hintRow(Hint hint) {
    late final Color color;
    switch (hint.severity) {
      case Severity.ok:
        color = Colors.greenAccent;
        break;
      case Severity.warning:
        color = Colors.amberAccent;
        break;
      case Severity.critical:
        color = Colors.redAccent;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(hint.text)),
        ],
      ),
    );
  }
}

/// Zeigt einen zentrierten Hinweistext, wenn für den Zeitraum keine Daten vorliegen.
class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
