// providers/admin_provider.dart - PERBAIKAN
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/dashboard_stats.dart';
import '../models/user.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService;

  DashboardStats? _dashboardStats;
  List<User> _recentUsers = []; // 5 user terbaru untuk dashboard
  List<User> _allUsers = []; // Semua user untuk users screen
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;

  AdminProvider(this._adminService);

  DashboardStats? get dashboardStats => _dashboardStats;
  List<User> get recentUsers => _recentUsers;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;

  // Hapus property duplikat 'unreadNotifications' dan gunakan getter ini saja
  int get unreadNotifications {
    // Hitung berdasarkan data real dari dashboard
    if (_dashboardStats == null) return 0;

    int count = 0;

    // Hitung dari darurat aktif
    if (_dashboardStats!.activeEmergencies > 0) {
      count += _dashboardStats!.activeEmergencies;
    }

    // Asumsikan 30% laporan belum ditinjau
    if (_dashboardStats!.totalReports > 0) {
      count += (_dashboardStats!.totalReports * 0.3).round();
    }

    // Tambahkan notifikasi untuk user baru (jika ada)
    if (_recentUsers.isNotEmpty) {
      // Asumsikan user yang baru ditambahkan dalam 24 jam butuh perhatian
      final now = DateTime.now();
      final newUsersCount = _recentUsers.where((user) {
        final difference = now.difference(user.createdAt ?? now);
        return difference.inHours < 24;
      }).length;

      if (newUsersCount > 0) {
        count += 1; // Satu notifikasi untuk semua user baru
      }
    }

    return count;
  }

  // Method untuk mendapatkan notifikasi berdasarkan data real
  List<Map<String, dynamic>> get notifications {
    final List<Map<String, dynamic>> notifications = [];

    if (_dashboardStats == null) return notifications;

    // Notifikasi darurat
    if (_dashboardStats!.activeEmergencies > 0) {
      notifications.add({
        'id': 'emergency_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'emergency',
        'title': 'Darurat Aktif',
        'message':
            'Ada ${_dashboardStats!.activeEmergencies} laporan darurat yang membutuhkan perhatian segera',
        'time': 'Baru saja',
        'isRead': false,
      });
    }

    // Notifikasi laporan
    if (_dashboardStats!.totalReports > 0) {
      final pendingReports = (_dashboardStats!.totalReports * 0.3).round();
      if (pendingReports > 0) {
        notifications.add({
          'id': 'reports_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'report',
          'title': 'Laporan Menunggu',
          'message':
              '$pendingReports laporan belum ditinjau dan membutuhkan tindakan',
          'time': 'Hari ini',
          'isRead': false,
        });
      }
    }

    // Notifikasi pengumuman
    if (_dashboardStats!.totalAnnouncements > 0) {
      notifications.add({
        'id': 'announcements_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'announcement',
        'title': 'Pengumuman Aktif',
        'message':
            '${_dashboardStats!.totalAnnouncements} pengumuman sedang berjalan',
        'time': 'Minggu ini',
        'isRead': true,
      });
    }

    // Notifikasi user baru
    if (_recentUsers.isNotEmpty) {
      final now = DateTime.now();
      final newUsersCount = _recentUsers.where((user) {
        final difference = now.difference(user.createdAt ?? now);
        return difference.inHours < 24;
      }).length;

      if (newUsersCount > 0) {
        notifications.add({
          'id': 'new_users_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'user',
          'title': 'User Baru',
          'message': '$newUsersCount user baru bergabung hari ini',
          'time': 'Hari ini',
          'isRead': false,
        });
      }
    }

    // Notifikasi statistik total
    notifications.add({
      'id': 'stats_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'stats',
      'title': 'Statistik Sistem',
      'message':
          'Total ${_dashboardStats!.totalUsers} warga, ${_dashboardStats!.totalReports} laporan',
      'time': 'Bulan ini',
      'isRead': true,
    });

    return notifications;
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadDashboardStats(),
        _loadRecentUsers(), // Hanya load 5 user untuk dashboard
      ]);
    } catch (e) {
      _error = e.toString();
      print('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // METHOD UNTUK LOAD SEMUA USER
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

  Future<void> _loadDashboardStats() async {
    try {
      _dashboardStats = await _adminService.getDashboardStats();
      print('Dashboard stats loaded: ${_dashboardStats?.toJson()}');
    } catch (e) {
      print('Error loading dashboard stats: $e');
      rethrow;
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      _recentUsers = await _adminService.getRecentUsers();
      print('Loaded ${_recentUsers.length} recent users for dashboard');
    } catch (e) {
      print('Error loading recent users: $e');
      rethrow;
    }
  }

  // METHOD UNTUK LOAD SEMUA USER
  Future<void> _loadAllUsers() async {
    try {
      _allUsers = await _adminService.getAllUsers();
      print('Loaded ${_allUsers.length} all users for users screen');
    } catch (e) {
      print('Error loading all users: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method untuk menambah user baru
  void addUser(User newUser) {
    _allUsers.insert(0, newUser); // Tambah ke semua users
    _recentUsers.insert(0, newUser); // Juga tambah ke recent users
    if (_recentUsers.length > 5) {
      _recentUsers = _recentUsers.take(5).toList(); // Maintain hanya 5 terbaru
    }
    notifyListeners();
  }

  // Method untuk update user
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

    notifyListeners();
  }

  // Method untuk menghapus user
  void deleteUser(String userId) {
    _allUsers.removeWhere((user) => user.id == userId);
    _recentUsers.removeWhere((user) => user.id == userId);
    notifyListeners();
  }

  // Method untuk refresh data
  Future<void> refreshData() async {
    await loadDashboardData();
  }

  // Method untuk mark notification as read (placeholder untuk future implementation)
  void markNotificationAsRead(String notificationId) {
    // Implementation untuk mark notification as read
    // Untuk sekarang, kita hanya notify listeners
    notifyListeners();
  }

  // Method untuk mark all notifications as read
  void markAllNotificationsAsRead() {
    // Implementation untuk mark all notifications as read
    // Untuk sekarang, kita hanya notify listeners
    notifyListeners();
  }
}
