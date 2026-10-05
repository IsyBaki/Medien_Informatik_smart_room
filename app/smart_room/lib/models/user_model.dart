// Entspricht einem Dokument in der Firestore-Collection users/{uid}.
class UserModel {
  final String uid;
  final String email;
  final double? preferredTemperature;
  final bool notificationsEnabled;

  UserModel({
    required this.uid,
    required this.email,
    this.preferredTemperature,
    this.notificationsEnabled = true,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      preferredTemperature: (map['preferredTemperature'] as num?)?.toDouble(),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'preferredTemperature': preferredTemperature,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
