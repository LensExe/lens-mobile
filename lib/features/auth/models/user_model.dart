class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'client' or 'photographer'
  final String phone;
  final String city;
  final String gender;
  final String dateOfBirth;
  final String address;
  final String avatarUrl;
  final bool saveAsDefault;
  final bool twoFactorEnabled;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.city = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.address = '',
    this.avatarUrl = '',
    this.saveAsDefault = false,
    this.twoFactorEnabled = false,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? city,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? avatarUrl,
    bool? saveAsDefault,
    bool? twoFactorEnabled,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      saveAsDefault: saveAsDefault ?? this.saveAsDefault,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
}

class ActiveSession {
  final String id;
  final String deviceName;
  final String location;
  final String lastActive;
  final bool isCurrent;

  ActiveSession({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });
}

