// providers/admin_provider.dart - IMPLEMENTASI AUTO-REFRESH & NOTIFICATION SYSTEM LENGKAP
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar, Text;
import 'package:flutter/src/widgets/framework.dart';
import '../services/admin_service.dart';
import '../models/dashboard_stats.dart';
import '../models/user.dart';

class AdminProvider with ChangeNotifier {
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = true;
  final AdminService _adminService;

  DashboardStats? _dashboardStats;
  List<User> _recentUsers = [];
  List<User> _allUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;

  // Untuk tracking data sebelumnya untuk deteksi perubahan
  DashboardStats? _previousStats;
  List<User> _previousRecentUsers = [];
  DateTime _lastUpdate = DateTime.now();

  // Notification system
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _emergencies = [];
  List<Map<String, dynamic>> _reports = [];

  AdminProvider(this._adminService);

  DashboardStats? get dashboardStats => _dashboardStats;
  List<User> get recentUsers => _recentUsers;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;
  DateTime get lastUpdate => _lastUpdate;
  bool get isAutoRefreshEnabled => _isAutoRefreshEnabled;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get emergencies => _emergencies;
  List<Map<String, dynamic>> get reports => _reports;

  // Hitung jumlah notifikasi yang belum dibaca
  int get unreadNotifications {
    return _notifications
        .where((notification) => !notification['isRead'])
        .length;
  }

  // Hitung jumlah emergency yang belum dibaca
  int getUnreadEmergencyCount() {
    return _emergencies.where((emergency) => !emergency['isRead']).length;
  }

  // Hitung jumlah laporan yang belum dibaca
  int getUnreadReportCount() {
    return _reports.where((report) => !report['isRead']).length;
  }

  BuildContext? _context;

  // Method untuk set context (dipanggil dari screen)
  void setContext(BuildContext context) {
    _context = context;
  }
  
  int getPendingBillsCount() {
  // Ini adalah contoh implementasi - sesuaikan dengan data aktual Anda
  return dashboardStats?.pendingBills ?? 0;
}

  // ==================== AUTO-REFRESH IMPLEMENTATION ====================

  // Method untuk memulai auto-refresh
  void startAutoRefresh() {
    if (_autoRefreshTimer != null && _autoRefreshTimer!.isActive) {
      return; // Sudah berjalan
    }

    print('🔄 Memulai auto-refresh...');

    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isAutoRefreshEnabled) {
        _checkForNewData();
      }
    });
  }

  // Method untuk menghentikan auto-refresh
  void stopAutoRefresh() {
    print('⏹️ Menghentikan auto-refresh...');
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // Method untuk toggle auto-refresh
  void setAutoRefresh(bool enabled) {
    _isAutoRefreshEnabled = enabled;
    if (enabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
    notifyListeners();
  }

  // Method untuk mengecek data baru
  Future<void> _checkForNewData() async {
    try {
      print('🔍 Mengecek data baru...');

      // Simpan data sebelumnya untuk perbandingan
      _previousStats = _dashboardStats != null
          ? DashboardStats.fromJson(_dashboardStats!.toJson())
          : null;
      _previousRecentUsers = List<User>.from(_recentUsers);

      // Load data terbaru tanpa mengubah loading state
      await _loadDashboardStats(silent: true);
      await _loadRecentUsers(silent: true);

      // Generate notifications dari data terbaru
      _generateNotifications();

      // Cek jika ada perubahan data
      final hasNewData = _hasDataChanged();

      if (hasNewData) {
        print('📊 Data baru ditemukan! Memperbarui UI...');
        _lastUpdate = DateTime.now();
        _showNewDataIndicator();
      } else {
        print('✅ Tidak ada perubahan data');
      }
    } catch (error) {
      print('❌ Error dalam auto-refresh: $error');
    }
  }

  // Method untuk membandingkan data lama dan baru
  bool _hasDataChanged() {
    if (_previousStats == null || _dashboardStats == null) {
      return false;
    }

    // Bandingkan stats utama
    final statsChanged =
        _previousStats!.totalUsers != _dashboardStats!.totalUsers ||
        _previousStats!.totalAnnouncements !=
            _dashboardStats!.totalAnnouncements ||
        _previousStats!.activeEmergencies !=
            _dashboardStats!.activeEmergencies ||
        _previousStats!.totalReports != _dashboardStats!.totalReports;

    // Bandingkan recent users (berdasarkan ID dan count)
    final usersChanged =
        _previousRecentUsers.length != _recentUsers.length ||
        _recentUsers.any(
          (user) => !_previousRecentUsers.any((prev) => prev.id == user.id),
        );

    return statsChanged || usersChanged;
  }

  // Method untuk menampilkan indikator data baru
  void _showNewDataIndicator() {
    // Trigger rebuild untuk semua consumer
    notifyListeners();

    // Tampilkan snackbar jika context tersedia
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('Data terbaru telah dimuat'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== NOTIFICATION SYSTEM ====================

  // Generate notifications dari data dashboard
  void _generateNotifications() {
    _notifications.clear();
    _emergencies.clear();
    _reports.clear();

    if (_dashboardStats == null) return;

    final now = DateTime.now();

    // Generate emergency notifications
    if (_dashboardStats!.activeEmergencies > 0) {
      for (int i = 0; i < _dashboardStats!.activeEmergencies; i++) {
        final emergency = {
          'id': 'emergency_${now.millisecondsSinceEpoch}_$i',
          'type': 'emergency',
          'title': 'Laporan Darurat ${i + 1}',
          'message': 'Ada laporan darurat yang membutuhkan perhatian segera',
          'time': 'Baru saja',
          'isRead': false,
          'timestamp': now,
        };
        _emergencies.add(emergency);
        _notifications.add(emergency);
      }
    }

    // Generate report notifications
    if (_dashboardStats!.totalReports > 0) {
      final pendingReports = (_dashboardStats!.totalReports * 0.3).round();
      for (int i = 0; i < pendingReports; i++) {
        final report = {
          'id': 'report_${now.millisecondsSinceEpoch}_$i',
          'type': 'report',
          'title': 'Laporan Menunggu ${i + 1}',
          'message': 'Laporan belum ditinjau dan membutuhkan tindakan',
          'time': 'Hari ini',
          'isRead': false,
          'timestamp': now,
        };
        _reports.add(report);
        _notifications.add(report);
      }
    }

    // Generate announcement notifications
    if (_dashboardStats!.totalAnnouncements > 0) {
      _notifications.add({
        'id': 'announcement_${now.millisecondsSinceEpoch}',
        'type': 'announcement',
        'title': 'Pengumuman Aktif',
        'message':
            '${_dashboardStats!.totalAnnouncements} pengumuman sedang berjalan',
        'time': 'Minggu ini',
        'isRead': true,
        'timestamp': now,
      });
    }

    // Generate new user notifications
    if (_recentUsers.isNotEmpty) {
      final newUsersCount = _recentUsers.where((user) {
        final difference = now.difference(user.createdAt);
        return difference.inHours < 24;
      }).length;

      if (newUsersCount > 0) {
        _notifications.add({
          'id': 'new_user_${now.millisecondsSinceEpoch}',
          'type': 'user',
          'title': 'User Baru',
          'message': '$newUsersCount user baru bergabung hari ini',
          'time': 'Hari ini',
          'isRead': false,
          'timestamp': now,
        });
      }
    }

    // Generate stats notification
    _notifications.add({
      'id': 'stats_${now.millisecondsSinceEpoch}',
      'type': 'stats',
      'title': 'Statistik Sistem',
      'message':
          'Total ${_dashboardStats!.totalUsers} warga, ${_dashboardStats!.totalReports} laporan',
      'time': 'Bulan ini',
      'isRead': true,
      'timestamp': now,
    });

    // Sort notifications by timestamp (newest first)
    _notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    _emergencies.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    _reports.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
  }

  // Mark single notification as read
  void markNotificationAsRead(String notificationId) {
    final notificationIndex = _notifications.indexWhere(
      (n) => n['id'] == notificationId,
    );
    if (notificationIndex != -1) {
      _notifications[notificationIndex]['isRead'] = true;
      notifyListeners();
    }

    // Juga update di emergencies dan reports jika ada
    final emergencyIndex = _emergencies.indexWhere(
      (e) => e['id'] == notificationId,
    );
    if (emergencyIndex != -1) {
      _emergencies[emergencyIndex]['isRead'] = true;
    }

    final reportIndex = _reports.indexWhere((r) => r['id'] == notificationId);
    if (reportIndex != -1) {
      _reports[reportIndex]['isRead'] = true;
    }
  }

  // Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
    for (var emergency in _emergencies) {
      emergency['isRead'] = true;
    }
    for (var report in _reports) {
      report['isRead'] = true;
    }
    notifyListeners();
  }

  // Mark all emergencies as read
  void markAllEmergenciesAsRead() {
    for (var emergency in _emergencies) {
      emergency['isRead'] = true;
    }
    // Juga update notifications yang terkait emergencies
    for (var notification in _notifications) {
      if (notification['type'] == 'emergency') {
        notification['isRead'] = true;
      }
    }
    notifyListeners();
  }

  // Mark all reports as read
  void markAllReportsAsRead() {
    for (var report in _reports) {
      report['isRead'] = true;
    }
    // Juga update notifications yang terkait reports
    for (var notification in _notifications) {
      if (notification['type'] == 'report') {
        notification['isRead'] = true;
      }
    }
    notifyListeners();
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _emergencies.clear();
    _reports.clear();
    notifyListeners();
  }

  // ==================== DATA LOADING METHODS ====================

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadDashboardStats(), _loadRecentUsers()]);
      _lastUpdate = DateTime.now();

      // Generate notifications setelah data dimuat
      _generateNotifications();

      // Mulai auto-refresh setelah load pertama
      if (_isAutoRefreshEnabled) {
        startAutoRefresh();
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers() async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      await _loadAllUsers();
    } catch (e) {
      _error = e.toString();
      print('Error loading all users: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> _loadDashboardStats({bool silent = false}) async {
    try {
      final newStats = await _adminService.getDashboardStats();

      // Only update if there's actual new data
      if (_dashboardStats == null ||
          _dashboardStats!.toJson().toString() !=
              newStats.toJson().toString()) {
        _dashboardStats = newStats;
        if (!silent) {
          notifyListeners();
        }
      }

      print('📈 Dashboard stats loaded: ${_dashboardStats?.toJson()}');
    } catch (e) {
      print('Error loading dashboard stats: $e');
      if (!silent) rethrow;
    }
  }

  Future<void> _loadRecentUsers({bool silent = false}) async {
    try {
      final newUsers = await _adminService.getRecentUsers();

      // Check if users list actually changed
      if (_recentUsers.length != newUsers.length ||
          _recentUsers.any(
            (user) => !newUsers.any((newUser) => newUser.id == user.id),
          )) {
        _recentUsers = newUsers;
        if (!silent) {
          notifyListeners();
        }
      }

      print('👥 Loaded ${_recentUsers.length} recent users for dashboard');
    } catch (e) {
      print('Error loading recent users: $e');
      if (!silent) rethrow;
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      _allUsers = await _adminService.getAllUsers();
      print('👥 Loaded ${_allUsers.length} all users for users screen');
    } catch (e) {
      print('Error loading all users: $e');
      rethrow;
    }
  }

  // ==================== DATA MANIPULATION METHODS ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void addUser(User newUser) {
    _allUsers.insert(0, newUser);
    _recentUsers.insert(0, newUser);
    if (_recentUsers.length > 5) {
      _recentUsers = _recentUsers.take(5).toList();
    }
    _lastUpdate = DateTime.now();

    // Generate ulang notifications
    _generateNotifications();

    notifyListeners();
  }

  void updateUser(User updatedUser) {
    final index = _allUsers.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      _allUsers[index] = updatedUser;
    }

    final recentIndex = _recentUsers.indexWhere(
      (user) => user.id == updatedUser.id,
    );
    if (recentIndex != -1) {
      _recentUsers[recentIndex] = updatedUser;
    }

    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  void deleteUser(String userId) {
    _allUsers.removeWhere((user) => user.id == userId);
    _recentUsers.removeWhere((user) => user.id == userId);
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  // Method untuk manual refresh
  Future<void> refreshData() async {
    print('🔄 Manual refresh triggered');
    await loadDashboardData();
  }

  // Method untuk force refresh (ignore cache)
  Future<void> forceRefresh() async {
    print('💥 Force refresh triggered');
    _previousStats = null;
    _previousRecentUsers = [];
    await loadDashboardData();
  }

  // Cleanup
  @override
  void dispose() {
    print('♻️ Disposing AdminProvider...');
    stopAutoRefresh();
    super.dispose();
  }
}
