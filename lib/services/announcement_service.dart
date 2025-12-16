// services/announcement_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/announcement.dart';

class AnnouncementService {
  static const String baseUrl =
      'https://wargakita.canadev.my.id'; // Ganti dengan URL API Anda

  // Tambahkan token management
  Future<Map<String, String>> _getHeaders() async {
    // Implement your token retrieval logic here
    final token = await _getToken(); // Get from secure storage
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getToken() async {
    // Implement token retrieval from shared preferences or secure storage
    return null; // Replace with actual token retrieval
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/announcements'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Announcement.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat pengumuman: $e');
    }
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'description': description,
          'targetAudience': targetAudience,
          'date': date.toIso8601String(),
          'day': day,
        }),
      );

      if (response.statusCode == 201 ||
          response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data['announcement'] != null) {
          return Announcement.fromJson(data['announcement']);
        }
        return Announcement.fromJson(data);
      } else {
        throw Exception('Gagal membuat pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal membuat pengumuman: $e');
    }
  }

  Future<Announcement> updateAnnouncement({
    required int id,
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'description': description,
          'targetAudience': targetAudience,
          'date': date.toIso8601String(),
          'day': day,
        }),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Announcement.fromJson(data);
      } else {
        throw Exception('Gagal mengupdate pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mengupdate pengumuman: $e');
    }
  }

  Future<void> deleteAnnouncement(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        throw Exception('Gagal menghapus pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus pengumuman: $e');
    }
  }

  Future<Announcement> getAnnouncementById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Announcement.fromJson(data);
      } else {
        throw Exception(
          'Gagal memuat detail pengumuman: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Gagal memuat detail pengumuman: $e');
    }
  }
}
