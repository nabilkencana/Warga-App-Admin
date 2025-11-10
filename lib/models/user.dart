class User {
  final int id;
  final String namaLengkap;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      namaLengkap: json['namaLengkap']?.toString() ?? 'No Name',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt']?.toString() ?? DateTime.now().toString(),
      ),
    );
  }
}
