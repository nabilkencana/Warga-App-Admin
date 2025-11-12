// services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';

class ReportService {
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getToken() async {
    // Implement token retrieval from shared preferences or secure storage
    return null; // Replace with actual token retrieval
  }

  Future<List<Report>> getReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Report.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan: $e');
    }
  }

  Future<List<Report>> getReportsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/category/$category'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Report.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan: $e');
    }
  }

  Future<List<Report>> getReportsByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/status/$status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Report.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan: $e');
    }
  }

  Future<List<Report>> searchReports(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/search?keyword=$keyword'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Report.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal mencari laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mencari laporan: $e');
    }
  }

  Future<Report> createReport({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'title': title,
        'description': description,
        'category': category,
      };

      // Only add fields if they have values
      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestData['imageUrl'] = imageUrl;
      }

      if (userId != null) {
        requestData['userId'] = userId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        throw Exception('Gagal membuat laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal membuat laporan: $e');
    }
  }

  Future<Report> updateReport({
    required int id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> requestData = {};

      // Only add fields that are provided
      if (title != null) requestData['title'] = title;
      if (description != null) requestData['description'] = description;
      if (category != null) requestData['category'] = category;
      if (imageUrl != null) requestData['imageUrl'] = imageUrl;

      final response = await http.put(
        Uri.parse('$baseUrl/reports/$id'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        throw Exception('Gagal mengupdate laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mengupdate laporan: $e');
    }
  }

  Future<Report> updateReportStatus(int id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/reports/$id/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        throw Exception('Gagal mengupdate status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mengupdate status: $e');
    }
  }

  Future<void> deleteReport(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal menghapus laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus laporan: $e');
    }
  }

  Future<Report> getReportById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        throw Exception('Gagal memuat detail laporan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat detail laporan: $e');
    }
  }

  // Get available categories
  Future<List<String>> getCategories() async {
    return [
      'Umum',
      'Infrastruktur',
      'Sampah',
      'Keamanan',
      'Kesehatan',
      'Lingkungan',
    ];
  }

  // Get available statuses
  Future<List<String>> getStatuses() async {
    return ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'REJECTED'];
  }
}
