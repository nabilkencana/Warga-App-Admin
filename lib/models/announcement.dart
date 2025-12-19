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
      targetAudience: json['targetAudience'] ?? 'ALL_RESIDENTS',
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
      'title': title,
      'description': description,
      'targetAudience': targetAudience,
      'date': date.toIso8601String(),
      'day': day,
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
      return '${(difference.inDays / 7).floor()} minggu yang lalu';
    }
    return '${(difference.inDays / 30).floor()} bulan yang lalu';
  }

  String get formattedDate {
    final List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Color get audienceColor {
    switch (targetAudience) {
      case 'ALL_RESIDENTS':
        return Color(0xFF3B82F6); // Blue sesuai backend
      case 'ADMIN':
        return Colors.red;
      case 'VOLUNTEER':
        return Colors.green;
      default:
        if (targetAudience.startsWith('RT_')) {
          return Colors.orange;
        }
        return Colors.grey;
    }
  }

  String get audienceText {
    switch (targetAudience) {
      case 'ALL_RESIDENTS':
        return 'Semua Warga';
      case 'ADMIN':
        return 'Admin';
      case 'VOLUNTEER':
        return 'Volunteer';
      default:
        if (targetAudience.startsWith('RT_')) {
          return 'RT ${targetAudience.split('_')[1]}';
        }
        return targetAudience;
    }
  }

  IconData get audienceIcon {
    switch (targetAudience) {
      case 'ALL_RESIDENTS':
        return Icons.people;
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'VOLUNTEER':
        return Icons.volunteer_activism;
      default:
        if (targetAudience.startsWith('RT_')) {
          return Icons.home;
        }
        return Icons.announcement;
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

// Response model untuk create/update
// ✅ Response model untuk create announcement
class AnnouncementResponse {
  final String message;
  final Announcement announcement;

  AnnouncementResponse({required this.message, required this.announcement});

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      message: json['message'] ?? '',
      announcement: Announcement.fromJson(json['announcement'] ?? json),
    );
  }
}

// ✅ Response model untuk delete announcement
class DeleteResponse {
  final String message;
  final String title;

  DeleteResponse({required this.message, required this.title});

  factory DeleteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteResponse(
      message: json['message'] ?? '',
      title: json['title'] ?? '',
    );
  }
}

