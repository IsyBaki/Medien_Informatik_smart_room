/// Zentrale Konstanten: Geräte-Namen, Firestore-Struktur, ESP32-Konfiguration.
/// So stehen wichtige Namen an einer Stelle statt verstreut im Code.
class AppConstants {
  // Gerätenamen -- werden sowohl in Firestore als auch im ESP32-Protokoll
  // als Schlüssel verwendet (siehe esp32/smart_room_esp32.ino).
  static const String deviceLight = 'light';
  static const String deviceFan = 'fan';
  static const String deviceParty = 'party';

  // Firestore-Struktur
  static const String usersCollection = 'users';
  static const String roomCollection = 'smart_room';
  static const String roomStatusDoc = 'status';
  static const String roomHistorySubcollection = 'history';
  static const String roomEventsSubcollection = 'events';

  // ESP32-WebSocket
  static const int esp32DefaultPort = 81;
}
