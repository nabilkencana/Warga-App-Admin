// models/report.dart

import 'package:flutter/material.dart';

class Report {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? imageUrl;
  final int? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.imageUrl,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Umum',
      status: json['status'] ?? 'PENDING',
      imageUrl: json['imageUrl'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu';
      case 'IN_PROGRESS':
        return 'Diproses';
      case 'COMPLETED':
        return 'Selesai';
      case 'REJECTED':
        return 'Ditolak';
      default:
        return status;
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'infrastruktur':
        return Icons.construction;
      case 'sampah':
        return Icons.delete;
      case 'keamanan':
        return Icons.security;
      case 'kesehatan':
        return Icons.medical_services;
      case 'lingkungan':
        return Icons.nature;
      case 'umum':
      default:
        return Icons.report_problem;
    }
  }

  String get categoryText {
    switch (category.toLowerCase()) {
      case 'infrastruktur':
        return 'Infrastruktur';
      case 'sampah':
        return 'Sampah';
      case 'keamanan':
        return 'Keamanan';
      case 'kesehatan':
        return 'Kesehatan';
      case 'lingkungan':
        return 'Lingkungan';
      case 'umum':
      default:
        return 'Umum';
    }
  }
}
