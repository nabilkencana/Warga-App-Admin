// providers/report_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();
  static const String baseUrl = 'https://wargakita.canadev.my.id';
  static const String imageBaseUrl =
      'https://wargakita.canadev.my.id'; // Base URL untuk gambar

  List<Report> _reports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'Semua';
  String _selectedCategory = 'Semua';
  int? _currentUserId;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMore = true;

  List<Report> get reports => _filteredReports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  String get selectedCategory => _selectedCategory;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMore => _hasMore;

  final List<String> _statusFilters = [
    'Semua',
    'PENDING',
    'PROCESSING', // Diubah dari IN_PROGRESS
    'RESOLVED', // Diubah dari COMPLETED
    'REJECTED',
  ];

  final List<String> _categoryFilters = [
    'Semua',
    'Umum',
    'Infrastruktur',
    'Sampah',
    'Keamanan',
    'Kesehatan',
    'Lingkungan',
  ];

  List<String> get statusFilters => _statusFilters;
  List<String> get categoryFilters => _categoryFilters;

  // Set current user ID
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
    print('Current user ID set to: $userId'); // Tambahkan debug
    notifyListeners();
  }
  Future<void> loadReports({bool refresh = false, String? searchQuery}) async {
    if (refresh) {
      _resetPagination();
    }

    if (!_hasMore && !refresh) return;

    _setLoading(true);
    _error = null;

    try {
      final ApiResponse<List<Report>> response = await _reportService
          .getReports(page: _currentPage, limit: 10, search: searchQuery);

      if (refresh) {
        _reports = response.data;
      } else {
        _reports.addAll(response.data);
      }

      _updatePagination(response.meta);
      _applyFilters();

      if (!refresh) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading reports: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReportsByCategory(
    String category, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _resetPagination();
    }

    if (!_hasMore && !refresh) return;

    _setLoading(true);
    _error = null;

    try {
      final ApiResponse<List<Report>> response = await _reportService
          .getReportsByCategory(category, page: _currentPage, limit: 10);

      if (refresh) {
        _reports = response.data;
      } else {
        _reports.addAll(response.data);
      }

      _updatePagination(response.meta);
      _applyFilters();

      if (!refresh) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading reports by category: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReportsByStatus(
    String status, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _resetPagination();
    }

    if (!_hasMore && !refresh) return;

    _setLoading(true);
    _error = null;

    try {
      final ApiResponse<List<Report>> response = await _reportService
          .getReportsByStatus(status, page: _currentPage, limit: 10);

      if (refresh) {
        _reports = response.data;
      } else {
        _reports.addAll(response.data);
      }

      _updatePagination(response.meta);
      _applyFilters();

      if (!refresh) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading reports by status: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchReports(String keyword, {bool refresh = false}) async {
    if (refresh) {
      _resetPagination();
    }

    if (!_hasMore && !refresh) return;

    _setLoading(true);
    _error = null;

    try {
      final ApiResponse<List<Report>> response = await _reportService
          .searchReports(keyword, page: _currentPage, limit: 10);

      if (refresh) {
        _reports = response.data;
      } else {
        _reports.addAll(response.data);
      }

      _updatePagination(response.meta);
      _applyFilters();

      if (!refresh) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
      print('Error searching reports: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserReports(int userId, {bool refresh = false}) async {
    if (refresh) {
      _resetPagination();
    }

    if (!_hasMore && !refresh) return;

    _setLoading(true);
    _error = null;

    try {
      final ApiResponse<List<Report>> response = await _reportService
          .getReportsByUserId(userId, page: _currentPage, limit: 10);

      if (refresh) {
        _reports = response.data;
      } else {
        _reports.addAll(response.data);
      }

      _updatePagination(response.meta);
      _applyFilters();

      if (!refresh) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading user reports: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Report> createReport({
    required String title,
    required String description,
    required String category,
    File? imageFile,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final newReport = await _reportService.createReport(
        title: title,
        description: description,
        category: category,
        imageFile: imageFile,
        userId: _currentUserId,
      );

      _reports.insert(0, newReport);
      _applyFilters();
      notifyListeners();

      return newReport;
    } catch (e) {
      _error = e.toString();
      print('Error creating report: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Report> updateReport({
    required int id,
    String? title,
    String? description,
    String? category,
    File? imageFile, required bool deleteImage,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedReport = await _reportService.updateReport(
        id: id,
        title: title,
        description: description,
        category: category,
        imageFile: imageFile,
      );

      final index = _reports.indexWhere((report) => report.id == id);
      if (index != -1) {
        _reports[index] = updatedReport;
        _applyFilters();
        notifyListeners();
      }

      return updatedReport;
    } catch (e) {
      _error = e.toString();
      print('Error updating report: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> updateReportStatus(int id, String status) async {
    _setLoading(true);
    _error = null;

    try {
      print('🔄 Updating status for report $id to $status');

      final result = await _reportService.updateReportStatus(id, status);

      // Update local data
      final index = _reports.indexWhere((report) => report.id == id);
      if (index != -1) {
        _reports[index] = result['report'];
        _applyFilters();
        notifyListeners();
      }

      print('✅ Status updated successfully');
      return result;
    } on Exception catch (e) {
      _error = 'Gagal mengupdate status: $e';
      print('❌ Error in updateReportStatus: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> deleteReport(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _reportService.deleteReport(id);

      _reports.removeWhere((report) => report.id == id);
      _applyFilters();
      notifyListeners();

      return result;
    } catch (e) {
      _error = e.toString();
      print('Error deleting report: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Report> getReportDetail(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final report = await _reportService.getReportById(id);
      return report;
    } catch (e) {
      _error = e.toString();
      print('Error getting report detail: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    _setLoading(true);
    _error = null;

    try {
      final stats = await _reportService.getReportStats();
      return stats;
    } catch (e) {
      _error = e.toString();
      print('Error getting statistics: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredReports = _reports.where((report) {
      final statusMatch =
          _selectedFilter == 'Semua' ||
          report.status.toUpperCase() == _selectedFilter.toUpperCase();
      final categoryMatch =
          _selectedCategory == 'Semua' || report.category == _selectedCategory;
      return statusMatch && categoryMatch;
    }).toList();

    // Sort by createdAt descending (newest first)
    _filteredReports.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _resetPagination() {
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasMore = true;
    _reports.clear();
    _filteredReports.clear();
  }

  void _updatePagination(MetaData meta) {
    _totalPages = meta.totalPages;
    _totalItems = meta.total;
    _hasMore = _currentPage < meta.totalPages;
  }

  // Clear all data
  void clearData() {
    _resetPagination();
    _selectedFilter = 'Semua';
    _selectedCategory = 'Semua';
    _error = null;
    notifyListeners();
  }

  // Load more data
  Future<void> loadMore({String? searchQuery}) async {
    if (!_hasMore || _isLoading) return;

    if (_selectedCategory != 'Semua') {
      await loadReportsByCategory(_selectedCategory);
    } else if (_selectedFilter != 'Semua') {
      await loadReportsByStatus(_selectedFilter);
    } else {
      await loadReports(searchQuery: searchQuery);
    }
  }

  // Refresh data
  Future<void> refreshData({String? searchQuery}) async {
    if (_selectedCategory != 'Semua') {
      await loadReportsByCategory(_selectedCategory, refresh: true);
    } else if (_selectedFilter != 'Semua') {
      await loadReportsByStatus(_selectedFilter, refresh: true);
    } else {
      await loadReports(refresh: true, searchQuery: searchQuery);
    }
  }

  // Statistics (local calculation)
  Map<String, int> getLocalReportStats() {
    return {
      'total': _reports.length,
      'pending': _reports
          .where((r) => r.status.toUpperCase() == 'PENDING')
          .length,
      'processing': _reports
          .where((r) => r.status.toUpperCase() == 'PROCESSING')
          .length,
      'resolved': _reports
          .where((r) => r.status.toUpperCase() == 'RESOLVED')
          .length,
      'rejected': _reports
          .where((r) => r.status.toUpperCase() == 'REJECTED')
          .length,
    };
  }

  // Check if user can edit report (owner or admin)
  bool canEditReport(Report report) {
    // Implement your logic here - for example:
    // return _currentUserId == report.userId || _isAdmin;
    return _currentUserId == report.userId; // Hanya pemilik yang bisa edit
  }

  // Check if user can delete report
  bool canDeleteReport(Report report) {
    // Hanya pemilik atau admin yang bisa hapus
    return _currentUserId == report.userId; // Tambahkan logika admin jika ada
  }

  // Update method untuk mendapatkan URL gambar lengkap
  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Jika sudah full URL, return langsung
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Jika path dimulai dengan /, tambahkan base URL
    if (imagePath.startsWith('/')) {
      return '$imageBaseUrl$imagePath';
    }

    // Default: tambahkan base URL dengan slash
    return '$imageBaseUrl/$imagePath';
  }

  // Get unique categories from loaded reports
  List<String> getLoadedCategories() {
    final categories = _reports
        .map((r) => r.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort();
    return ['Semua', ...categories];
  }

  // Get report by ID (from loaded reports)
  Report? getReportByIdLocal(int id) {
    try {
      return _reports.firstWhere((report) => report.id == id);
    } catch (e) {
      return null;
    }
  }
}
