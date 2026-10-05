// Zeitraum-Auswahl für die History-Seite.
enum HistoryRange { today, yesterday, last7Days, last30Days, all }

extension HistoryRangeX on HistoryRange {
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

  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

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
        return DateTime(2000); // praktisch "kein unteres Limit"
    }
  }

  // null bedeutet "bis jetzt"
  DateTime? get to {
    return this == HistoryRange.yesterday ? _startOfToday : null;
  }
}
