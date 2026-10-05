import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Ereignistypen, die im Ereignisverlauf (History) protokolliert werden:
// nur Geräteschaltungen + Login.
enum RoomEventType {
  lightOn,
  lightOff,
  fanOn,
  fanOff,
  partyOn,
  partyOff,
  login;

  static RoomEventType fromKey(String key) {
    return RoomEventType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => RoomEventType.login,
    );
  }

  // Schlüssel, wie er in Firestore gespeichert wird.
  String get key {
    switch (this) {
      case RoomEventType.lightOn:
        return 'light_on';
      case RoomEventType.lightOff:
        return 'light_off';
      case RoomEventType.fanOn:
        return 'fan_on';
      case RoomEventType.fanOff:
        return 'fan_off';
      case RoomEventType.partyOn:
        return 'party_on';
      case RoomEventType.partyOff:
        return 'party_off';
      case RoomEventType.login:
        return 'login';
    }
  }

  String get label {
    switch (this) {
      case RoomEventType.lightOn:
        return 'Licht eingeschaltet';
      case RoomEventType.lightOff:
        return 'Licht ausgeschaltet';
      case RoomEventType.fanOn:
        return 'Lüfter eingeschaltet';
      case RoomEventType.fanOff:
        return 'Lüfter ausgeschaltet';
      case RoomEventType.partyOn:
        return 'Party-Modus eingeschaltet';
      case RoomEventType.partyOff:
        return 'Party-Modus ausgeschaltet';
      case RoomEventType.login:
        return 'Benutzer hat sich angemeldet';
    }
  }

  String get description {
    switch (this) {
      case RoomEventType.lightOn:
        return 'Die Beleuchtung wurde eingeschaltet.';
      case RoomEventType.lightOff:
        return 'Die Beleuchtung wurde ausgeschaltet.';
      case RoomEventType.fanOn:
        return 'Der Lüfter wurde aktiviert.';
      case RoomEventType.fanOff:
        return 'Der Lüfter wurde deaktiviert.';
      case RoomEventType.partyOn:
        return 'Der Party-Modus wurde gestartet.';
      case RoomEventType.partyOff:
        return 'Der Party-Modus wurde beendet.';
      case RoomEventType.login:
        return 'Benutzer hat sich erfolgreich angemeldet.';
    }
  }

  // für die Filter-Chips im Ereignisverlauf
  RoomEventCategory get category {
    switch (this) {
      case RoomEventType.lightOn:
      case RoomEventType.lightOff:
        return RoomEventCategory.light;
      case RoomEventType.fanOn:
      case RoomEventType.fanOff:
        return RoomEventCategory.fan;
      case RoomEventType.partyOn:
      case RoomEventType.partyOff:
        return RoomEventCategory.party;
      case RoomEventType.login:
        return RoomEventCategory.user;
    }
  }

  IconData get icon {
    switch (this) {
      case RoomEventType.lightOn:
      case RoomEventType.lightOff:
        return Icons.lightbulb;
      case RoomEventType.fanOn:
      case RoomEventType.fanOff:
        return Icons.air;
      case RoomEventType.partyOn:
      case RoomEventType.partyOff:
        return Icons.celebration;
      case RoomEventType.login:
        return Icons.login;
    }
  }
}

// Kategorien für die Filter-Chips in der History.
enum RoomEventCategory {
  light,
  fan,
  party,
  user;

  String get label {
    switch (this) {
      case RoomEventCategory.light:
        return 'Licht';
      case RoomEventCategory.fan:
        return 'Lüfter';
      case RoomEventCategory.party:
        return 'Party';
      case RoomEventCategory.user:
        return 'Benutzer';
    }
  }
}

// Entspricht einem Dokument in smart_room/status/events.
class RoomEvent {
  final RoomEventType type;
  final DateTime timestamp;
  final String? byUid;

  RoomEvent({required this.type, required this.timestamp, this.byUid});

  factory RoomEvent.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return RoomEvent(
      type: RoomEventType.fromKey(map['type'] as String? ?? ''),
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      byUid: map['byUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.key,
      'timestamp': Timestamp.fromDate(timestamp),
      'byUid': byUid,
    };
  }
}
