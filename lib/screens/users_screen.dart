// screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/user.dart';
import 'user_detail_screen.dart'; // Import halaman detail

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load data users ketika screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadAllUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Data Warga'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Semua (${_getAllUsersCount()})'),
            Tab(text: 'Admin (${_getAdminUsersCount()})'),
            Tab(text: 'Warga (${_getRegularUsersCount()})'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return _buildLoadingState();
          }

          if (adminProvider.error != null) {
            return _buildErrorState(adminProvider);
          }

          final users = adminProvider.allUsers;

          if (users.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab Semua - Tampilkan semua user yang registrasi
              _buildUsersList(users, 'all'),
              // Tab Admin
              _buildUsersList(
                users
                    .where((user) => user.role.toLowerCase() == 'admin')
                    .toList(),
                'admin',
              ),
              // Tab Warga
              _buildUsersList(
                users
                    .where((user) => user.role.toLowerCase() == 'user')
                    .toList(),
                'user',
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: Colors.blue[800],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // METHOD UNTUK MENDAPATKAN COUNT UNTUK TAB LABEL
  int _getAllUsersCount() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    return adminProvider.allUsers.length;
  }

  int _getAdminUsersCount() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    return adminProvider.allUsers
        .where((user) => user.role.toLowerCase() == 'admin')
        .length;
  }

  int _getRegularUsersCount() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    return adminProvider.allUsers
        .where((user) => user.role.toLowerCase() == 'user')
        .length;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[800]),
          SizedBox(height: 16),
          Text(
            'Memuat data users...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AdminProvider adminProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Gagal memuat data users',
              style: TextStyle(
                fontSize: 18,
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
                adminProvider.loadAllUsers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada data users',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambah user baru',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> users, String filter) {
    if (users.isEmpty) {
      String message = '';
      switch (filter) {
        case 'admin':
          message = 'Belum ada data admin';
          break;
        case 'user':
          message = 'Belum ada data warga';
          break;
        default:
          message = 'Belum ada data users';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getRoleColor(user.role).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to user detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailScreen(userId: user.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getRoleColor(user.role),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.namaLengkap.isNotEmpty
                      ? user.namaLengkap[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              user.namaLengkap,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Bergabung: ${_formatDate(user.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue[800]),
                SizedBox(width: 8),
                Text(
                  'Tambah User Baru',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.blue[800],
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'user',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Warga'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Admin'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'volunteer',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.volunteer_activism,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Volunteer'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed:
                    _nameController.text.isEmpty ||
                        _emailController.text.isEmpty ||
                        _passwordController.text.isEmpty
                    ? null
                    : () => _addNewUser(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addNewUser(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Create new user object
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      namaLengkap: _nameController.text,
      email: _emailController.text,
      role: _selectedRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to provider (in real app, this would be API call)
    adminProvider.addUser(newUser);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('User berhasil ditambahkan!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Close dialog
    Navigator.pop(context);

    // Switch to appropriate tab based on role
    if (_selectedRole == 'admin') {
      _tabController.animateTo(1);
    } else if (_selectedRole == 'user') {
      _tabController.animateTo(2);
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'volunteer':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
