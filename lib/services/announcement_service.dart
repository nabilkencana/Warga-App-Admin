// services/announcement_service.dart - REVISI
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:wargaapp_admin/providers/auth_provider.dart';
import '../models/announcement.dart';

class AnnouncementService {
  static const String baseUrl = 'https://wargakita.canadev.my.id';

  // Method untuk mendapatkan headers dengan token dari context
  static Future<Map<String, String>> getHeaders(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('✅ Token ditemukan: ${token.substring(0, 20)}...');
    } else {
      print('❌ Token TIDAK ditemukan di AuthProvider');
    }

    return headers;
  }

  // Method untuk get announcements yang memerlukan context
  Future<List<Announcement>> getAnnouncements(BuildContext context) async {
    try {
      final headers = await getHeaders(context);
      print('📡 Mengirim request ke: $baseUrl/announcements');
      print('📋 Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/announcements'),
        headers: headers,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode.toString().startsWith('2')) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Berhasil memuat ${data.length} pengumuman');
        return data.map((item) => Announcement.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        print('❌ Error 401: Unauthorized');
        print('🔍 Response detail: ${response.body}');
        throw Exception(
          'Token tidak valid atau sudah kedaluwarsa. Silakan login kembali.',
        );
      } else if (response.statusCode == 403) {
        throw Exception('Anda tidak memiliki izin untuk mengakses pengumuman');
      } else {
        throw Exception('Gagal memuat pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading announcements: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> uploadImage(BuildContext context, File imageFile) async {
    try {
      final headers = await getHeaders(context);
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/announcements/upload-image'),
      );
      
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
      });
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal mengupload gambar: ${response.body}');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }

  Future<AnnouncementResponse> createAnnouncement({
    required BuildContext context,
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
    String? imageUrl,
    String? imagePublicId,
    bool isHighlight = false,
  }) async {
    try {
      final headers = await getHeaders(context);

      print('📡 Mengirim request POST ke: $baseUrl/announcements');
      print('📋 Data: title=$title, audience=$targetAudience');

      final response = await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
          'targetAudience': targetAudience,
          'date': date.toIso8601String(),
          'day': day,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (imagePublicId != null) 'imagePublicId': imagePublicId,
          'isHighlight': isHighlight,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return AnnouncementResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login kembali.');
      } else if (response.statusCode == 403) {
        throw Exception('Anda tidak memiliki izin untuk membuat pengumuman');
      } else {
        throw Exception(
          'Gagal membuat pengumuman: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error creating announcement: $e');
      rethrow;
    }
  }

  Future<Announcement> updateAnnouncement({
    required BuildContext context,
    required int id,
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
    String? imageUrl,
    String? imagePublicId,
    bool isHighlight = false,
  }) async {
    try {
      final headers = await getHeaders(context);

      final response = await http.put(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
          'targetAudience': targetAudience,
          'date': date.toIso8601String(),
          'day': day,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (imagePublicId != null) 'imagePublicId': imagePublicId,
          'isHighlight': isHighlight,
        }),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Announcement.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login kembali.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Anda tidak memiliki izin untuk mengupdate pengumuman ini',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Pengumuman tidak ditemukan');
      } else {
        throw Exception('Gagal mengupdate pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<DeleteResponse> deleteAnnouncement({
    required BuildContext context,
    required int id,
  }) async {
    try {
      final headers = await getHeaders(context);

      final response = await http.delete(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: headers,
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return DeleteResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login kembali.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Anda tidak memiliki izin untuk menghapus pengumuman ini',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Pengumuman tidak ditemukan');
      } else {
        throw Exception('Gagal menghapus pengumuman: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Announcement> getAnnouncementById({
    required BuildContext context,
    required int id,
  }) async {
    try {
      final headers = await getHeaders(context);

      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Announcement.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Pengumuman tidak ditemukan');
      } else {
        throw Exception(
          'Gagal memuat detail pengumuman: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
