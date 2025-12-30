// services/report_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';

class ReportService {
  static const String baseUrl = 'https://wargakita.canadev.my.id';

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await _getToken();
    final headers = <String, String>{};

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<String?> _getToken() async {
    // Implement token retrieval from shared preferences or secure storage
    return await SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));
    // return null; // Replace with actual token retrieval
  }

  Future<ApiResponse<List<Report>>> getReports({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/reports').replace(
        queryParameters: queryParams,
      );

      print('📡 GET ${uri.toString()}'); // Debug log

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'];

        return ApiResponse<List<Report>>(
          success: true,
          data: reportsData.map((item) => Report.fromJson(item)).toList(),
          meta: MetaData.fromJson(data['meta']),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memuat laporan');
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan: $e');
    }
  }

  Future<ApiResponse<List<Report>>> getReportsByCategory(
    String category, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/reports/category/$category').replace(
        queryParameters: queryParams,
      );

      print('📡 GET ${uri.toString()}'); // Debug log

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'];

        return ApiResponse<List<Report>>(
          success: true,
          data: reportsData.map((item) => Report.fromJson(item)).toList(),
          meta: MetaData.fromJson(data['meta']),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Gagal memuat laporan berdasarkan kategori',
        );
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan berdasarkan kategori: $e');
    }
  }

  Future<ApiResponse<List<Report>>> getReportsByStatus(
    String status, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/reports/status/$status').replace(
        queryParameters: queryParams,
      );

      print('📡 GET ${uri.toString()}'); // Debug log

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'];

        return ApiResponse<List<Report>>(
          success: true,
          data: reportsData.map((item) => Report.fromJson(item)).toList(),
          meta: MetaData.fromJson(data['meta']),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Gagal memuat laporan berdasarkan status',
        );
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan berdasarkan status: $e');
    }
  }

  Future<ApiResponse<List<Report>>> searchReports(
    String keyword, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/reports/search/$keyword').replace(
        queryParameters: queryParams,
      );

      print('📡 GET ${uri.toString()}'); // Debug log

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'];

        return ApiResponse<List<Report>>(
          success: true,
          data: reportsData.map((item) => Report.fromJson(item)).toList(),
          meta: MetaData.fromJson(data['meta']),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mencari laporan');
      }
    } catch (e) {
      throw Exception('Gagal mencari laporan: $e');
    }
  }

  Future<Report> createReport({
    required String title,
    required String description,
    required String category,
    File? imageFile,
    int? userId,
  }) async {
    try {
      if (imageFile != null) {
        // Upload dengan multipart/form-data jika ada file
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/reports'),
        );

        request.headers.addAll(await _getHeaders(isMultipart: true));

        request.fields['title'] = title;
        request.fields['description'] = description;
        request.fields['category'] = category;
        if (userId != null) {
          request.fields['userId'] = userId.toString();
        }

        final imageBytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'report_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);

        print('📤 POST ${request.url} dengan file: ${imageFile.path}'); // Debug log

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return Report.fromJson(data);
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal membuat laporan');
        }
      } else {
        // Upload tanpa file
        final Map<String, dynamic> requestData = {
          'title': title,
          'description': description,
          'category': category,
        };

        if (userId != null) {
          requestData['userId'] = userId;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/reports'),
          headers: await _getHeaders(),
          body: json.encode(requestData),
        );

        print('📤 POST ${response.request?.url}'); // Debug log

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return Report.fromJson(data);
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal membuat laporan');
        }
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
    File? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        // Update dengan multipart/form-data jika ada file baru
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/reports/$id'),
        );

        request.headers.addAll(await _getHeaders(isMultipart: true));

        if (title != null) request.fields['title'] = title;
        if (description != null) request.fields['description'] = description;
        if (category != null) request.fields['category'] = category;

        final imageBytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'report_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);

        print('📤 PUT ${request.url} dengan file: ${imageFile.path}'); // Debug log

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode.toString().startsWith('2')) {
          final data = json.decode(response.body);
          return Report.fromJson(data);
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal mengupdate laporan');
        }
      } else {
        // Update tanpa file
        final Map<String, dynamic> requestData = {};

        if (title != null) requestData['title'] = title;
        if (description != null) requestData['description'] = description;
        if (category != null) requestData['category'] = category;

        final response = await http.put(
          Uri.parse('$baseUrl/reports/$id'),
          headers: await _getHeaders(),
          body: json.encode(requestData),
        );

        print('📤 PUT ${response.request?.url}'); // Debug log

        if (response.statusCode.toString().startsWith('2')) {
          final data = json.decode(response.body);
          return Report.fromJson(data);
        } else {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal mengupdate laporan');
        }
      }
    } catch (e) {
      throw Exception('Gagal mengupdate laporan: $e');
    }
  }

  Future<Map<String, dynamic>> updateReportStatus(int id, String status) async {
    try {
      print('📤 Updating report status: ID=$id, Status=$status');

      // ⚠️ GANTI dari PATCH ke PUT sesuai dengan backend
      final response = await http.put(
        Uri.parse('$baseUrl/reports/$id/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status.toUpperCase()}),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status updated successfully');

        return {
          'message': data['message'] ?? 'Status berhasil diubah',
          'report': Report.fromJson(data['report'] ?? data),
        };
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Status tidak valid');
      } else if (response.statusCode == 404) {
        throw Exception('Laporan tidak ditemukan');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengupdate status');
      }
    } on FormatException catch (e) {
      print('❌ JSON Format Error: $e');
      throw Exception('Format response tidak valid');
    } catch (e) {
      print('❌ Error updating status: $e');
      throw Exception('Gagal mengupdate status: $e');
    }
  }

  Future<Map<String, dynamic>> deleteReport(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$id'),
        headers: await _getHeaders(),
      );

      print('🗑️ DELETE ${response.request?.url}'); // Debug log

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return {
          'message': data['message'],
          'deletedReport': data['deletedReport'],
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menghapus laporan');
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

      print('📡 GET ${response.request?.url}'); // Debug log

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memuat detail laporan');
      }
    } catch (e) {
      throw Exception('Gagal memuat detail laporan: $e');
    }
  }

  Future<ApiResponse<List<Report>>> getReportsByUserId(
    int userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/reports/user/$userId').replace(
        queryParameters: queryParams,
      );

      print('📡 GET ${uri.toString()}'); // Debug log

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'];

        return ApiResponse<List<Report>>(
          success: true,
          data: reportsData.map((item) => Report.fromJson(item)).toList(),
          meta: MetaData.fromJson(data['meta']),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Gagal memuat laporan pengguna',
        );
      }
    } catch (e) {
      throw Exception('Gagal memuat laporan pengguna: $e');
    }
  }

  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/stats/summary'), // ✅ Diperbaiki endpoint
        headers: await _getHeaders(),
      );

      print('📡 GET ${response.request?.url}'); // Debug log

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Gagal memuat statistik laporan',
        );
      }
    } catch (e) {
      throw Exception('Gagal memuat statistik laporan: $e');
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

  // Get available statuses - disesuaikan dengan backend
  Future<List<String>> getStatuses() async {
    return ['PENDING', 'PROCESSING', 'RESOLVED', 'REJECTED'];
  }
}

// Tambahkan model untuk ApiResponse dan MetaData jika belum ada
class ApiResponse<T> {
  final bool success;
  final T data;
  final MetaData meta;

  ApiResponse({
    required this.success,
    required this.data,
    required this.meta,
  });
}

class MetaData {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final Map<String, dynamic>? additional;

  MetaData({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.additional,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      additional: json['additional'] != null
          ? Map<String, dynamic>.from(json['additional'])
          : null,
    );
  }
}