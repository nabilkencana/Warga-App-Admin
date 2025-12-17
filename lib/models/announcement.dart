// models/announcement.dart

import 'package:flutter/material.dart';

class Announcement {
  final int id;
  final String title;
  final String description;
  final String targetAudience;
  final DateTime date;
  final String day;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Admin? admin;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAudience,
    required this.date,
    required this.day,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.admin,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetAudience: json['targetAudience'] ?? 'ALL',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      day: json['day'] ?? '',
      createdBy: json['createdBy'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      admin: json['admin'] != null ? Admin.fromJson(json['admin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAudience': targetAudience,
      'date': date.toIso8601String(),
      'day': day,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'admin': admin?.toJson(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m yang lalu';
    if (difference.inHours < 24) return '${difference.inHours}j yang lalu';
    if (difference.inDays < 7) return '${difference.inDays}h yang lalu';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}minggu yang lalu';
    }
    return '${(difference.inDays / 30).floor()}bulan yang lalu';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color get audienceColor {
    switch (targetAudience) {
      case 'ALL':
        return Colors.blue;
      case 'VOLUNTEER':
        return Colors.green;
      case 'ADMIN':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get audienceText {
    switch (targetAudience) {
      case 'ALL':
        return 'Semua User';
      case 'VOLUNTEER':
        return 'Volunteer';
      case 'ADMIN':
        return 'Admin';
      default:
        return targetAudience;
    }
  }
}

class Admin {
  final int id;
  final String namaLengkap;
  final String email;

  Admin({required this.id, required this.namaLengkap, required this.email});

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? 0,
      namaLengkap: json['namaLengkap'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'namaLengkap': namaLengkap, 'email': email};
  }
}
