// screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({super.key, required this.token});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSection(),
            Expanded(child: _buildDashboardContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WARGA KITA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Hai Admin!!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                'Waktunya cek data!!',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_none,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildTab('Semua', 0),
          SizedBox(width: 16),
          _buildTab('Poling Banyak', 1),
          SizedBox(width: 16),
          _buildTab('Belum ditinjau', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[800]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return _buildLoadingState();
        }

        if (adminProvider.error != null) {
          return _buildErrorState(adminProvider);
        }

        return _buildStatsGrid(adminProvider);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[800]),
          SizedBox(height: 16),
          Text('Memuat data...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorState(AdminProvider adminProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            adminProvider.error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              adminProvider.clearError();
              adminProvider.loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminProvider adminProvider) {
    final stats = adminProvider.dashboardStats;

    final statItems = [
      StatItem(
        title: 'Data Warga',
        count: stats?.totalUsers ?? 334,
        subtitle: 'Users',
        icon: Icons.people_outline,
        color: Colors.blue,
        onTap: () {
          Navigator.pushNamed(context, '/users');
        },
      ),
      StatItem(
        title: 'Pengumuman',
        count: stats?.totalAnnouncements ?? 10,
        subtitle: 'Pengumuman',
        icon: Icons.announcement_outlined,
        color: Colors.orange,
        onTap: () {
          Navigator.pushNamed(context, '/announcements');
        },
      ),
      StatItem(
        title: 'Darurat',
        count: stats?.activeEmergencies ?? 2,
        subtitle: 'Pemberitahuan',
        icon: Icons.warning_amber_outlined,
        color: Colors.red,
        onTap: () {
          Navigator.pushNamed(context, '/emergencies');
        },
      ),
      StatItem(
        title: 'Volunteers',
        count: stats?.totalVolunteers ?? 10,
        subtitle: 'Volunteers',
        icon: Icons.volunteer_activism_outlined,
        color: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, '/volunteers');
        },
      ),
      StatItem(
        title: 'Laporan',
        count: stats?.totalReports ?? 15,
        subtitle: 'Keluhan',
        icon: Icons.report_problem_outlined,
        color: Colors.purple,
        onTap: () {
          Navigator.pushNamed(context, '/reports');
        },
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: statItems.length,
        itemBuilder: (context, index) {
          return _buildStatCard(statItems[index]);
        },
      ),
    );
  }

  Widget _buildStatCard(StatItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.count.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatItem {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  StatItem({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
