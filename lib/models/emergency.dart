// models/emergency.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class Emergency {
  final int id;
  final String type;
  final String? details;
  final String? location;
  final String? latitude;
  final String? longitude;
  final bool needVolunteer;
  final int volunteerCount;
  final String status;
  final int? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Volunteer> volunteers;

  Emergency({
    required this.id,
    required this.type,
    this.details,
    this.location,
    this.latitude,
    this.longitude,
    required this.needVolunteer,
    required this.volunteerCount,
    required this.status,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.volunteers = const [],
  });

  factory Emergency.fromJson(Map<String, dynamic> json) {
    return Emergency(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      details: json['details'],
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      needVolunteer: json['needVolunteer'] ?? false,
      volunteerCount: json['volunteerCount'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      volunteers: json['volunteers'] != null
          ? (json['volunteers'] as List)
                .map((v) => Volunteer.fromJson(v))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'details': details,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'needVolunteer': needVolunteer,
      'volunteerCount': volunteerCount,
      'status': status,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'volunteers': volunteers.map((v) => v.toJson()).toList(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m yang lalu';
    if (difference.inHours < 24) return '${difference.inHours}j yang lalu';
    if (difference.inDays < 7) return '${difference.inDays}h yang lalu';
    if (difference.inDays < 30)
      return '${(difference.inDays / 7).floor()}minggu yang lalu';
    return '${(difference.inDays / 30).floor()}bulan yang lalu';
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.red;
      case 'RESOLVED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.grey;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Aktif';
      case 'RESOLVED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'PENDING':
        return 'Menunggu';
      default:
        return status;
    }
  }

  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'kebakaran':
      case 'fire':
        return Icons.local_fire_department;
      case 'banjir':
      case 'flood':
        return Icons.flood;
      case 'gempa':
      case 'earthquake':
        return Icons.landscape;
      case 'kecelakaan':
      case 'accident':
        return Icons.car_crash;
      case 'medis':
      case 'medical':
        return Icons.medical_services;
      case 'bencana alam':
      case 'natural disaster':
        return Icons.nature;
      default:
        return Icons.warning;
    }
  }

  String get typeText {
    switch (type.toLowerCase()) {
      case 'kebakaran':
      case 'fire':
        return 'Kebakaran';
      case 'banjir':
      case 'flood':
        return 'Banjir';
      case 'gempa':
      case 'earthquake':
        return 'Gempa Bumi';
      case 'kecelakaan':
      case 'accident':
        return 'Kecelakaan';
      case 'medis':
      case 'medical':
        return 'Darurat Medis';
      case 'bencana alam':
      case 'natural disaster':
        return 'Bencana Alam';
      default:
        return type;
    }
  }

  int get approvedVolunteersCount {
    return volunteers.where((v) => v.status == 'APPROVED').length;
  }

  bool get canVolunteer => needVolunteer && status == 'ACTIVE';
}

class Volunteer {
  final int id;
  final int emergencyId;
  final int? userId;
  final String? userName;
  final String? userPhone;
  final String? skills;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Volunteer({
    required this.id,
    required this.emergencyId,
    this.userId,
    this.userName,
    this.userPhone,
    this.skills,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id'] ?? 0,
      emergencyId: json['emergencyId'] ?? 0,
      userId: json['userId'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      skills: json['skills'],
      status: json['status'] ?? 'REGISTERED',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emergencyId': emergencyId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'skills': skills,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'REGISTERED':
        return 'Terdaftar';
      case 'APPROVED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'REGISTERED':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
