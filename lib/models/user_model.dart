// models/user_model.dart
class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? accessToken;
  final String? picture;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.accessToken,
    this.picture,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['namaLengkap'] ?? 'User',
      role: json['role']?.toString().toUpperCase() ?? 'USER',
      accessToken: json['access_token'] ?? json['accessToken'],
      picture: json['picture'] ?? json['fotoProfil'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'access_token': accessToken,
      'picture': picture,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isUser => role.toUpperCase() == 'USER';

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? accessToken,
    String? picture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      picture: picture ?? this.picture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
