// screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_management_app/models/dashboard_stats.dart';
import 'package:user_management_app/models/user.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      if (!adminProvider.isInitialized) {
        adminProvider.loadDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AdminProvider>(context, listen: false).refresh();
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && !adminProvider.isInitialized) {
            return _buildLoading();
          }

          if (adminProvider.error != null) {
            return _buildError(adminProvider);
          }

          return _buildDashboard(adminProvider);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading dashboard data...'),
        ],
      ),
    );
  }

  Widget _buildError(AdminProvider adminProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Error Loading Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              adminProvider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                adminProvider.clearError();
                adminProvider.refresh();
              },
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(AdminProvider adminProvider) {
    final stats = adminProvider.dashboardStats;
    final users = adminProvider.recentUsers;

    if (stats == null) {
      return _buildLoading();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Stats
          _buildStatsSection(stats),
          SizedBox(height: 24),

          // Recent Users
          _buildRecentUsersSection(users),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Users',
              stats.totalUsers,
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Reports',
              stats.totalReports,
              Icons.report,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Emergencies',
              stats.totalEmergencies,
              Icons.warning,
              Colors.red,
            ),
            _buildStatCard(
              'Active Emergencies',
              stats.activeEmergencies,
              Icons.emergency,
              Colors.red,
            ),
            _buildStatCard(
              'Total Volunteers',
              stats.totalVolunteers,
              Icons.volunteer_activism,
              Colors.green,
            ),
            _buildStatCard(
              'Announcements',
              stats.totalAnnouncements,
              Icons.announcement,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsersSection(List<User> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Users (${users.length})',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          child: users.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No users available'),
                )
              : Column(
                  children: users.map((user) => _buildUserTile(user)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildUserTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(user.role),
        child: Text(
          user.namaLengkap.isNotEmpty ? user.namaLengkap[0].toUpperCase() : 'U',
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(user.namaLengkap),
      subtitle: Text(user.email),
      trailing: Chip(
        label: Text(
          user.role.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _getRoleColor(user.role),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'volunteer':
        return Colors.green;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
