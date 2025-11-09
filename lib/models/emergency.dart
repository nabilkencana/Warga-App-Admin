import 'package:user_management_app/models/user.dart';

class Emergency {
  final String id;
  final String title;
  final String description;
  final String status;
  final String location;
  final User user;
  final DateTime createdAt;
  final DateTime updatedAt;

  Emergency({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Emergency.fromJson(Map<String, dynamic> json) {
    return Emergency(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      location: json['location'],
      user: User.fromJson(json['user']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
