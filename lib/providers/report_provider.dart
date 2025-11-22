// providers/report_provider.dart
import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();
  static const String baseUrl = 'http://wargakita.canadev.my.id';
  static const String imageBaseUrl =
      'http://wargakita.canadev.my.id'; // Base URL untuk gambar

  List<Report> _reports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'Semua';
  String _selectedCategory = 'Semua';
  int? _currentUserId;

  List<Report> get reports => _filteredReports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  String get selectedCategory => _selectedCategory;

  final List<String> _statusFilters = [
    'Semua',
    'PENDING',
    'IN_PROGRESS',
    'COMPLETED',
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
    notifyListeners();
  }

  Future<void> loadReports() async {
    _setLoading(true);
    _error = null;

    try {
      _reports = await _reportService.getReports();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReportsByCategory(String category) async {
    _setLoading(true);
    _error = null;

    try {
      _reports = await _reportService.getReportsByCategory(category);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReportsByStatus(String status) async {
    _setLoading(true);
    _error = null;

    try {
      _reports = await _reportService.getReportsByStatus(status);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchReports(String keyword) async {
    _setLoading(true);
    _error = null;

    try {
      _reports = await _reportService.searchReports(keyword);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
  }) async {
    _setLoading(true);

    try {
      final newReport = await _reportService.createReport(
        title: title,
        description: description,
        category: category,
        imageUrl: imageUrl,
        userId: _currentUserId,
      );

      _reports.insert(0, newReport);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateReport({
    required int id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    _setLoading(true);

    try {
      final updatedReport = await _reportService.updateReport(
        id: id,
        title: title,
        description: description,
        category: category,
        imageUrl: imageUrl,
      );

      final index = _reports.indexWhere((report) => report.id == id);
      if (index != -1) {
        _reports[index] = updatedReport;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateReportStatus(int id, String status) async {
    _setLoading(true);

    try {
      final updatedReport = await _reportService.updateReportStatus(id, status);
      final index = _reports.indexWhere((report) => report.id == id);
      if (index != -1) {
        _reports[index] = updatedReport;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteReport(int id) async {
    _setLoading(true);

    try {
      await _reportService.deleteReport(id);
      _reports.removeWhere((report) => report.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
          _selectedFilter == 'Semua' || report.status == _selectedFilter;
      final categoryMatch =
          _selectedCategory == 'Semua' || report.category == _selectedCategory;
      return statusMatch && categoryMatch;
    }).toList();

    _filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Statistics
  Map<String, int> getReportStats() {
    return {
      'total': _reports.length,
      'pending': _reports.where((r) => r.status == 'PENDING').length,
      'in_progress': _reports.where((r) => r.status == 'IN_PROGRESS').length,
      'completed': _reports.where((r) => r.status == 'COMPLETED').length,
      'rejected': _reports.where((r) => r.status == 'REJECTED').length,
    };
  }

  // Check if user can edit report (owner or admin)
  bool canEditReport(Report report) {
    // Implement your logic here - for example:
    // return _currentUserId == report.userId || _isAdmin;
    return true; // Temporary - replace with actual logic
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

}
