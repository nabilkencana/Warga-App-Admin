// providers/announcement_provider.dart - REVISI
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Tambahkan import ini
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementService _announcementService = AnnouncementService();

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _error;
  int? _currentUserId;
  bool _needsReLogin = false;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  bool get needsReLogin => _needsReLogin;
  int? get currentUserId => _currentUserId;

  // Set user ID dari AuthProvider
  void setCurrentUserInfo(int? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Clear error state
  void clearError() {
    _error = null;
    _needsReLogin = false;
    notifyListeners();
  }

  // ✅ PERBAIKI: Tambahkan parameter BuildContext
  Future<void> loadAnnouncements(BuildContext context) async {
    _isLoading = true;
    _error = null;
    _needsReLogin = false;
    notifyListeners();

    try {
      _announcements = await _announcementService.getAnnouncements(context);
      _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('✅ Berhasil memuat ${_announcements.length} pengumuman');
    } catch (e) {
      _error = e.toString();

      // Cek jika error karena authentication
      if (_error!.contains('Token tidak valid') ||
          _error!.contains('401') ||
          _error!.contains('Unauthorized')) {
        _needsReLogin = true;
        _error = 'Sesi Anda telah berakhir. Silakan login kembali.';
      }

      print('❌ Error dalam loadAnnouncements: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PERBAIKI: Update method signature untuk sesuai dengan service
  Future<void> addAnnouncement({
    required BuildContext context, // Ubah dari dynamic ke BuildContext
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
  }) async {
    _isCreating = true;
    _error = null;
    _needsReLogin = false;
    notifyListeners();

    try {
      // ✅ PERBAIKI: Sesuaikan dengan return type dari service
      final response = await _announcementService.createAnnouncement(
        context: context,
        title: title,
        description: description,
        targetAudience: targetAudience,
        date: date,
        day: day,
      );

      // ✅ Response adalah AnnouncementResponse, bukan Map<String, dynamic>
      // Tambahkan announcement ke list dari response
      _announcements.insert(0, response.announcement);
      notifyListeners();
    } catch (e) {
      _error = e.toString();

      if (_error!.contains('Token tidak valid') || _error!.contains('401')) {
        _needsReLogin = true;
      }

      rethrow;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // ✅ PERBAIKI: Update method signature untuk sesuai dengan service
  Future<void> updateAnnouncement({
    required BuildContext context, // Ubah dari dynamic ke BuildContext
    required int id,
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
  }) async {
    _isUpdating = true;
    _error = null;
    _needsReLogin = false;
    notifyListeners();

    try {
      final updatedAnnouncement = await _announcementService.updateAnnouncement(
        context: context, // ✅ Tambahkan parameter context
        id: id,
        title: title,
        description: description,
        targetAudience: targetAudience,
        date: date,
        day: day,
      );

      final index = _announcements.indexWhere((a) => a.id == id);
      if (index != -1) {
        _announcements[index] = updatedAnnouncement;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();

      if (_error!.contains('Token tidak valid') || _error!.contains('401')) {
        _needsReLogin = true;
      }

      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ✅ PERBAIKI: Update method signature untuk sesuai dengan service
  Future<void> deleteAnnouncement({
    required BuildContext context, // Ubah dari dynamic ke BuildContext
    required int id,
  }) async {
    _isDeleting = true;
    _error = null;
    _needsReLogin = false;
    notifyListeners();

    try {
      // ✅ Sesuaikan dengan service yang mengembalikan DeleteResponse
      await _announcementService.deleteAnnouncement(context: context, id: id);

      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();

      if (_error!.contains('Token tidak valid') || _error!.contains('401')) {
        _needsReLogin = true;
      }

      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Helper method untuk cek apakah user adalah pemilik pengumuman
  bool isAnnouncementOwner(Announcement announcement) {
    return _currentUserId != null && announcement.createdBy == _currentUserId;
  }
}
