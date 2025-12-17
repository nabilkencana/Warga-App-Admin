// models/report.dart
import 'package:flutter/material.dart';

class Report {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? imageUrl;
  final String? imagePublicId; // 🎯 NEW: Untuk Cloudinary public ID
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
    this.imagePublicId,
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
      imagePublicId: json['imagePublicId'],
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
      'imagePublicId': imagePublicId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  String get categoryText {
    switch (category.toLowerCase()) {
      case 'infrastructure':
      case 'infrastruktur':
        return 'Infrastruktur';
      case 'trash':
      case 'sampah':
        return 'Sampah';
      case 'security':
      case 'keamanan':
        return 'Keamanan';
      case 'health':
      case 'kesehatan':
        return 'Kesehatan';
      case 'environment':
      case 'lingkungan':
        return 'Lingkungan';
      case 'education':
      case 'pendidikan':
        return 'Pendidikan';
      case 'transportation':
      case 'transportasi':
        return 'Transportasi';
      case 'entertainment':
      case 'hiburan':
        return 'Hiburan';
      case 'other':
      case 'lainnya':
        return 'Lainnya';
      default:
        return 'Umum';
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

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'infrastructure':
      case 'infrastruktur':
        return Icons.construction;
      case 'trash':
      case 'sampah':
        return Icons.delete;
      case 'security':
      case 'keamanan':
        return Icons.security;
      case 'health':
      case 'kesehatan':
        return Icons.medical_services;
      case 'environment':
      case 'lingkungan':
        return Icons.eco;
      case 'education':
      case 'pendidikan':
        return Icons.school;
      case 'transportation':
      case 'transportasi':
        return Icons.directions_car;
      case 'entertainment':
      case 'hiburan':
        return Icons.movie;
      case 'other':
      case 'lainnya':
        return Icons.category;
      default:
        return Icons.report;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  // 🎯 NEW: Check if report has Cloudinary image
  bool get hasCloudinaryImage => imageUrl?.contains('cloudinary') == true;

  // 🎯 NEW: Get Cloudinary optimized URL
  String? get optimizedImageUrl {
    if (imageUrl == null) return null;

    // If it's a Cloudinary URL, you can add optimization parameters
    if (hasCloudinaryImage) {
      // Example: Add quality optimization
      return imageUrl!; // Add Cloudinary transformations if needed
    }

    return imageUrl;
  }

  Report copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? status,
    String? imageUrl,
    String? imagePublicId,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePublicId: imagePublicId ?? this.imagePublicId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
