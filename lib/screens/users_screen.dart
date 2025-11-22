// screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/user.dart';
import 'user_detail_screen.dart';
// Hapus import api_service yang tidak ada

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsersData();
  }

  void _loadUsersData() {
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
    _phoneController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Data Warga'),
        backgroundColor: Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Semua (${_getAllUsersCount()})'),
            Tab(text: 'Admin (${_getAdminUsersCount()})'),
            Tab(text: 'Warga (${_getRegularUsersCount()})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoadingUsers &&
                    adminProvider.allUsers.isEmpty) {
                  return _buildLoadingState();
                }

                if (adminProvider.error != null) {
                  return _buildErrorState(adminProvider);
                }

                final filteredUsers = _getFilteredUsers(adminProvider.allUsers);

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Color(0xFF1E88E5),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersList(filteredUsers, 'all'),
                      _buildUsersList(
                        filteredUsers
                            .where((user) => user.role.toLowerCase() == 'admin')
                            .toList(),
                        'admin',
                      ),
                      _buildUsersList(
                        filteredUsers
                            .where((user) => user.role.toLowerCase() == 'user')
                            .toList(),
                        'user',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: Color(0xFF1E88E5),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --------------------- SEARCH BAR ----------------------
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  List<User> _getFilteredUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;

    return users
        .where(
          (user) =>
              user.namaLengkap.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  // --------------------- LOADING, ERROR, EMPTY STATES ----------------------
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E88E5)),
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
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
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
            _searchQuery.isEmpty
                ? 'Belum ada data users'
                : 'Data tidak ditemukan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Tekan tombol + untuk menambah user baru'
                : 'Coba dengan kata kunci lain',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: Text('Tampilkan Semua'),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------- USERS LIST ----------------------
  Widget _buildUsersList(List<User> users, String filter) {
    if (users.isEmpty) {
      String message = _getEmptyMessage(filter);
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

  String _getEmptyMessage(String filter) {
    if (_searchQuery.isNotEmpty) return 'Data tidak ditemukan';

    switch (filter) {
      case 'admin':
        return 'Belum ada data admin';
      case 'user':
        return 'Belum ada data warga';
      default:
        return 'Belum ada data users';
    }
  }

  // --------------------- USER CARD ----------------------
  Widget _buildUserCard(User user) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getRoleColor(user.role).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToUserDetail(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.namaLengkap,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Bergabung: ${_formatDate(user.createdAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Role Badge & Actions
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // --------------------- ADD USER DIALOG ----------------------
  void _showAddUserDialog(BuildContext context) {
    _resetFormControllers();
    _selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Text(
                  'Tambah User Baru',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(child: _buildUserForm(setState)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _isFormValid() ? () => _addNewUser(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading ? _buildLoadingButton() : Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserForm(void Function(void Function()) setState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nama Lengkap *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email *',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password *',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          obscureText: true,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Nomor Telepon',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Alamat',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
              isExpanded: true,
              items: _buildRoleDropdownItems(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildRoleDropdownItems() {
    return [
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
            Icon(Icons.admin_panel_settings, color: Colors.red),
            SizedBox(width: 8),
            Text('Admin'),
          ],
        ),
      ),
    ];
  }


  // --------------------- CRUD OPERATIONS ----------------------
  Future<void> _addNewUser(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch,
        namaLengkap: _nameController.text,
        email: _emailController.text,
        role: _selectedRole,
        nomorTelepon: _phoneController.text.isEmpty ? null : _phoneController.text,
        alamat: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // POST - Add new user (simulasi)
      // Di sini Anda bisa menambahkan call API sebenarnya
      await Future.delayed(Duration(milliseconds: 500)); // Simulasi API call

      // Add to provider
      adminProvider.addUser(newUser);

      _showSuccessSnackbar(context, 'User berhasil ditambahkan!');
      Navigator.pop(context);
      _resetFormControllers();

      // Switch to appropriate tab
      if (_selectedRole == 'admin') {
        _tabController.animateTo(1);
      } else if (_selectedRole == 'user') {
        _tabController.animateTo(2);
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Gagal menambahkan user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser(BuildContext context, User user) async {
    setState(() => _isLoading = true);

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Create updated user object manually (karena tidak ada copyWith)
      final updatedUser = User(
        id: user.id,
        namaLengkap: _nameController.text,
        email: _emailController.text,
        role: _selectedRole,
        nomorTelepon: _phoneController.text.isEmpty ? null : _phoneController.text,
        alamat: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      // PUT/PATCH - Update user (simulasi)
      // Di sini Anda bisa menambahkan call API sebenarnya
      await Future.delayed(Duration(milliseconds: 500)); // Simulasi API call

      // Update in provider
      adminProvider.updateUser(updatedUser);

      _showSuccessSnackbar(context, 'User berhasil diupdate!');
      Navigator.pop(context);
      _resetFormControllers();
    } catch (e) {
      _showErrorSnackbar(context, 'Gagal mengupdate user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _deleteUser(BuildContext context, User user) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // DELETE - Delete user (simulasi)
      // Di sini Anda bisa menambahkan call API sebenarnya
      await Future.delayed(Duration(milliseconds: 500)); // Simulasi API call

      // Delete from provider
      adminProvider.deleteUser(user.id as String);

      _showSuccessSnackbar(context, 'User berhasil dihapus!');
      Navigator.pop(context); // Close confirmation dialog
    } catch (e) {
      _showErrorSnackbar(context, 'Gagal menghapus user: $e');
    }
  }

  // --------------------- HELPER METHODS ----------------------
  void _resetFormControllers() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  bool _isFormValid() {
    return _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  bool _isEditFormValid() {
    return _nameController.text.isNotEmpty && _emailController.text.isNotEmpty;
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _refreshData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadAllUsers();
  }

  void _navigateToUserDetail(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(userId: user.id),
      ),
    );
  }

  // --------------------- COUNT METHODS ----------------------
  int _getAllUsersCount() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    return _getFilteredUsers(adminProvider.allUsers).length;
  }

  int _getAdminUsersCount() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    return _getFilteredUsers(
      adminProvider.allUsers,
    ).where((user) => user.role.toLowerCase() == 'admin').length;
  }

  int _getRegularUsersCount() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    return _getFilteredUsers(
      adminProvider.allUsers,
    ).where((user) => user.role.toLowerCase() == 'user').length;
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'volunteer':
        return Colors.green;
      default:
        return Color(0xFF1E88E5);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
