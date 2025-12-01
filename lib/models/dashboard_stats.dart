class DashboardStats {
  final int totalUsers;
  final int totalReports;
  final int totalEmergencies;
  final int totalVolunteers;
  final int activeEmergencies;
  final int totalAnnouncements;
  final int totalBills;
  final int pendingBills;
  final int overdueBills;

  DashboardStats({
    required this.totalUsers,
    required this.totalReports,
    required this.totalEmergencies,
    required this.totalVolunteers,
    required this.activeEmergencies,
    required this.totalAnnouncements,
    required this.totalBills,
    required this.pendingBills,
    required this.overdueBills
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalReports: json['totalReports'] ?? 0,
      totalEmergencies: json['totalEmergencies'] ?? 0,
      totalVolunteers: json['totalVolunteers'] ?? 0,
      activeEmergencies: json['activeEmergencies'] ?? 0,
      totalAnnouncements: json['totalAnnouncements'] ?? 0,
      totalBills: json['totalBills'] ?? 0,
      pendingBills: json['pendingBills'] ?? 0,
      overdueBills: json['overdueBills'] ?? 0 
    );
  }

  Map<String , dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalAnnouncements': totalAnnouncements,
      'activeEmergencies': activeEmergencies,
      'totalReports': totalReports,
      'totalBills': totalBills, // ADD THIS
      'pendingBills': pendingBills, // ADD THIS
      'overdueBills': overdueBills, // ADD THIS
    };
  }
}
