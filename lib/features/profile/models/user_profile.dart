import 'dart:typed_data';

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarBytes,
  });

  const UserProfile.empty() : this(firstName: '', lastName: '', email: '');

  final String firstName;
  final String lastName;
  final String email;
  final Uint8List? avatarBytes;

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
    );
  }

  Map<String, Object?> toLocalJson() {
    return <String, Object?>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  Map<String, Object?> toRemoteJson() {
    return <String, Object?>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  static UserProfile fromMap(
    Map<String, Object?> map, {
    Uint8List? avatarBytes,
  }) {
    return UserProfile(
      firstName: (map['firstName'] as String? ?? '').trim(),
      lastName: (map['lastName'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      avatarBytes: avatarBytes,
    );
  }
}
