// models/dashboard_stats.dart
class DashboardStats {
  final int totalUsers;
  final int totalReports;
  final int totalEmergencies;
  final int totalVolunteers;
  final int activeEmergencies;
  final int totalAnnouncements;

  DashboardStats({
    required this.totalUsers,
    required this.totalReports,
    required this.totalEmergencies,
    required this.totalVolunteers,
    required this.activeEmergencies,
    required this.totalAnnouncements,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalReports: json['totalReports'] ?? 0,
      totalEmergencies: json['totalEmergencies'] ?? 0,
      totalVolunteers: json['totalVolunteers'] ?? 0,
      activeEmergencies: json['activeEmergencies'] ?? 0,
      totalAnnouncements: json['totalAnnouncements'] ?? 0,
    );
  }
}
