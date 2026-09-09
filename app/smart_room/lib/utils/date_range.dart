/// Zeitraum-Auswahl für die History-Seite.
enum HistoryRange { today, yesterday, last7Days, last30Days, all }

extension HistoryRangeX on HistoryRange {
  /// Anzeigetext für die Dropdown-Auswahl (z.B. "Letzte 7 Tage").
  String get label {
    switch (this) {
      case HistoryRange.today:
        return 'Heute';
      case HistoryRange.yesterday:
        return 'Gestern';
      case HistoryRange.last7Days:
        return 'Letzte 7 Tage';
      case HistoryRange.last30Days:
        return 'Letzte 30 Tage';
      case HistoryRange.all:
        return 'Gesamt';
    }
  }

  /// Mitternacht des heutigen Tages -- Basis für alle Zeitraum-Berechnungen.
  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Startzeitpunkt des Zeitraums (inklusive).
  DateTime get from {
    switch (this) {
      case HistoryRange.today:
        return _startOfToday;
      case HistoryRange.yesterday:
        return _startOfToday.subtract(const Duration(days: 1));
      case HistoryRange.last7Days:
        return _startOfToday.subtract(const Duration(days: 7));
      case HistoryRange.last30Days:
        return _startOfToday.subtract(const Duration(days: 30));
      case HistoryRange.all:
        // Praktisch "kein unteres Limit" -- vor dem Projektstart liegend.
        return DateTime(2000);
    }
  }

  /// Endzeitpunkt (exklusiv). `null` bedeutet "bis jetzt".
  DateTime? get to {
    return this == HistoryRange.yesterday ? _startOfToday : null;
  }
}
