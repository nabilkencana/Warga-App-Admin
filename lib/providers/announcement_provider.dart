// providers/announcement_provider.dart
import 'package:flutter/foundation.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementService _announcementService = AnnouncementService();

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;
  int? _currentUserId; // Untuk mengecek apakah user adalah pembuat pengumuman

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set current user ID (dari login)
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Cek apakah user adalah pembuat pengumuman
  bool isAnnouncementOwner(Announcement announcement) {
    return _currentUserId != null && announcement.createdBy == _currentUserId;
  }

  Future<void> loadAnnouncements() async {
    _setLoading(true);
    _error = null;

    try {
      _announcements = await _announcementService.getAnnouncements();
      _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAnnouncement({
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
  }) async {
    _setLoading(true);

    try {
      final newAnnouncement = await _announcementService.createAnnouncement(
        title: title,
        description: description,
        targetAudience: targetAudience,
        date: date,
        day: day,
      );

      _announcements.insert(0, newAnnouncement);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAnnouncement({
    required int id,
    required String title,
    required String description,
    required String targetAudience,
    required DateTime date,
    required String day,
  }) async {
    _setLoading(true);

    try {
      final updatedAnnouncement = await _announcementService.updateAnnouncement(
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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAnnouncement(int id) async {
    _setLoading(true);

    try {
      await _announcementService.deleteAnnouncement(id);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
