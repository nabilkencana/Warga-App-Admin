// models/auth_response.dart
class AuthResponse {
  final String message;
  final User? user;
  final String accessToken;

  AuthResponse({
    required this.message,
    required this.user,
    required this.accessToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      accessToken: json['access_token'] ?? '',
    );
  }
}

class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      // Konversi SATPAM menjadi SECURITY untuk routing
      role: _normalizeRole(json['role'] ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Helper method untuk normalisasi role
  static String _normalizeRole(String role) {
    if (role == 'SATPAM') {
      return 'SECURITY'; // SATPAM dianggap sebagai SECURITY untuk routing
    }
    return role;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';
  bool get isSecurity =>
      role == 'SECURITY' || role == 'SATPAM'; // UPDATE: Include SATPAM

  // Get original role (untuk tampilan)
  String get originalRole {
    // Simpan original role jika perlu
    return role;
  }
}