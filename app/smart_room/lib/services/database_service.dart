import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/room_event.dart';
import '../models/sensor_data.dart';
import '../models/user_model.dart';
import '../utils/date_range.dart';

// Kapselt den gesamten Zugriff auf Cloud Firestore.
//
// Struktur:
// - users/{uid}               -> Profil & Einstellungen pro Benutzer
// - smart_room/status         -> aktueller Gerätestatus (geteilt, 1 Raum)
// - smart_room/status/history -> historische Sensormesswerte mit Zeitstempel
// - smart_room/status/events  -> Ereignisverlauf (Schaltungen, Login)
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  DocumentReference<Map<String, dynamic>> get _roomStatus => _db
      .collection(AppConstants.roomCollection)
      .doc(AppConstants.roomStatusDoc);

  CollectionReference<Map<String, dynamic>> get _roomHistory =>
      _roomStatus.collection(AppConstants.roomHistorySubcollection);

  CollectionReference<Map<String, dynamic>> get _roomEvents =>
      _roomStatus.collection(AppConstants.roomEventsSubcollection);

  // --- Benutzerprofil & Einstellungen ---

  Future<void> createUserProfile({
    required String uid,
    required String email,
  }) async {
    await _users.doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'preferredTemperature': null,
      'notificationsEnabled': true,
    });
  }

  Stream<UserModel?> getUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return UserModel.fromMap(uid, data);
    });
  }

  Future<void> updateUserSettings({
    required String uid,
    double? preferredTemperature,
    bool? notificationsEnabled,
  }) async {
    final updates = <String, dynamic>{};
    if (preferredTemperature != null) {
      updates['preferredTemperature'] = preferredTemperature;
    }
    if (notificationsEnabled != null) {
      updates['notificationsEnabled'] = notificationsEnabled;
    }
    if (updates.isEmpty) return;
    await _users.doc(uid).set(updates, SetOptions(merge: true));
  }

  // --- Gerätestatus (geteilt für den Raum) ---

  Stream<Map<String, dynamic>> streamDeviceStatus() {
    return _roomStatus.snapshots().map((doc) => doc.data() ?? {});
  }

  Future<void> updateDeviceStatus({
    required String device,
    required bool state,
    required String updatedBy,
  }) async {
    await _roomStatus.set({
      device: state,
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastUpdatedBy': updatedBy,
    }, SetOptions(merge: true));
  }

  // Legt beim allerersten Start ein Status-Dokument mit Standardwerten an,
  // damit die App nicht dauerhaft "--" anzeigt. merge: true, damit bereits
  // vorhandene Werte nicht überschrieben werden.
  Future<void> ensureRoomDefaults() async {
    final snapshot = await _roomStatus.get();
    if (snapshot.exists) return;

    await _roomStatus.set({
      AppConstants.deviceLight: false,
      AppConstants.deviceFan: false,
      AppConstants.deviceParty: false,
    });
  }

  // --- Sensordaten ---

  Stream<SensorData?> streamLatestSensorData() {
    return _roomHistory
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SensorData.fromMap(snapshot.docs.first.data());
    });
  }

  // wird vom ESP32-Datenstrom aufgerufen, sobald echte Hardware verbunden ist
  Future<void> saveSensorReading(SensorData data) async {
    await _roomHistory.add(data.toMap());
  }

  // chronologisch aufsteigend, damit es sich direkt für die Diagramm-Anzeige
  // in der History eignet
  Stream<List<SensorData>> streamSensorHistory(HistoryRange range) {
    Query<Map<String, dynamic>> query = _roomHistory.where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(range.from),
    );
    final to = range.to;
    if (to != null) {
      query = query.where('timestamp', isLessThan: Timestamp.fromDate(to));
    }
    return query.orderBy('timestamp').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => SensorData.fromMap(doc.data()))
              .toList(),
        );
  }

  // --- Ereignisverlauf ---

  Future<void> logEvent(RoomEventType type, {String? byUid}) async {
    final event = RoomEvent(type: type, timestamp: DateTime.now(), byUid: byUid);
    await _roomEvents.add(event.toMap());
  }

  // neueste zuerst, damit sie direkt als Liste angezeigt werden können
  Stream<List<RoomEvent>> streamEvents(HistoryRange range) {
    Query<Map<String, dynamic>> query = _roomEvents.where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(range.from),
    );
    final to = range.to;
    if (to != null) {
      query = query.where('timestamp', isLessThan: Timestamp.fromDate(to));
    }
    return query.orderBy('timestamp', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => RoomEvent.fromMap(doc.data())).toList(),
        );
  }
}
