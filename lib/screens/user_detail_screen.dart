// screens/user_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  final UserService userService = UserService();

  UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final user = await widget.userService.getUserById(widget.userId);
      final stats = await widget.userService.getUserStats(widget.userId);

      return {'user': user, 'stats': stats, 'error': null};
    } catch (e) {
      return {'user': null, 'stats': null, 'error': e.toString()};
    }
  }

  void _refreshData() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Detail Profile'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data?['error'] != null) {
            return _buildErrorWidget(
              snapshot.data?['error'] ?? 'Terjadi kesalahan',
            );
          }

          final user = snapshot.data?['user'] as User?;
          final stats = snapshot.data?['stats'] as Map<String, int>?;

          if (user == null) {
            return _buildErrorWidget('User tidak ditemukan');
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(user),
                SizedBox(height: 32),

                // Verification Badge
                if (!user.isVerified) _buildVerificationWarning(),

                // Profile Information
                _buildProfileInfo(user),
                SizedBox(height: 24),

                // Account Stats
                _buildAccountStats(stats ?? {}),
                SizedBox(height: 24),

                // Actions
                _buildActionButtons(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _getRoleColor(user.role),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRoleColor(user.role).withOpacity(0.3),
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  user.namaLengkap.isNotEmpty
                      ? user.namaLengkap[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (user.isOnline ?? false)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          user.namaLengkap,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getRoleColor(user.role).withOpacity(0.3),
                ),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (user.isVerified) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'TERVERIFIKASI',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              user.bio!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationWarning() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Akun belum terverifikasi. Beberapa fitur mungkin terbatas.',
              style: TextStyle(color: Colors.orange[800], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[800], size: 20),
                SizedBox(width: 8),
                Text(
                  'Informasi Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user.email),
            _buildInfoRow(Icons.person, 'Nama Lengkap', user.namaLengkap),
            if (user.nik != null) _buildInfoRow(Icons.badge, 'NIK', user.nik!),
            _buildInfoRow(Icons.assignment_ind, 'Role', user.role),
            if (user.nomorTelepon != null)
              _buildInfoRow(Icons.phone, 'Telepon', user.nomorTelepon!),
            if (user.alamat != null)
              _buildInfoRow(Icons.location_on, 'Alamat', user.alamat!),
            if (user.kota != null)
              _buildInfoRow(Icons.location_city, 'Kota', user.kota!),
            _buildInfoRow(
              Icons.calendar_today,
              'Bergabung',
              _formatDetailedDate(user.createdAt),
            ),
            _buildInfoRow(
              Icons.update,
              'Terakhir Diupdate',
              _formatDetailedDate(user.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStats(Map<String, int> stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.blue[800],
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Statistik Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Laporan',
                  stats['laporan'].toString(),
                  Icons.report,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Darurat',
                  stats['darurat'].toString(),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Aktivitas',
                  stats['aktivitas'].toString(),
                  Icons.local_activity_rounded,
                  Colors.green,
                ),
              ],
            ),
            if (stats.values.every((count) => count == 0)) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Belum ada aktivitas tercatat',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, User user) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showMessageDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.blue[800]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message, color: Colors.blue[800]),
                    SizedBox(width: 8),
                    Text(
                      'Kirim Pesan',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showCallDialog(context, user.nomorTelepon);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Hubungi', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (user.role.toLowerCase() == 'volunteer')
          OutlinedButton(
            onPressed: () {
              _showVolunteerDetails(context);
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: Colors.green),
                SizedBox(width: 8),
                Text('Detail Volunteer', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),

        // Admin actions
        if (_isCurrentUserAdmin()) ...[
          SizedBox(height: 16),
          Divider(),
          Text(
            'Admin Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showRoleUpdateDialog(context, user);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.orange),
                  ),
                  child: Text(
                    'Ubah Role',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showVerificationDialog(context, user);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: user.isVerified ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    user.isVerified ? 'Batalkan Verifikasi' : 'Verifikasi',
                    style: TextStyle(
                      color: user.isVerified ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _refreshData, child: Text('Coba Lagi')),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[800]),
            SizedBox(width: 8),
            Text('Edit Profile'),
          ],
        ),
        content: Text('Fitur edit profile akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: Colors.blue[800])),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: Colors.blue[800]),
            SizedBox(width: 8),
            Text('Kirim Pesan'),
          ],
        ),
        content: Text('Fitur kirim pesan akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: Colors.blue[800])),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context, String? phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: Colors.blue[800]),
            SizedBox(width: 8),
            Text('Hubungi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phoneNumber == null)
              Text('Nomor telepon tidak tersedia.')
            else
              Text('Hubungi $phoneNumber?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          if (phoneNumber != null)
            ElevatedButton(
              onPressed: () {
                // Implement phone call
                Navigator.pop(context);
              },
              child: Text('Hubungi'),
            ),
        ],
      ),
    );
  }

  void _showVolunteerDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green),
            SizedBox(width: 8),
            Text('Detail Volunteer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi detail volunteer akan ditampilkan di sini.'),
            SizedBox(height: 16),
            _buildInfoRow(Icons.star, 'Rating', '4.8/5.0'),
            _buildInfoRow(Icons.assignment_turned_in, 'Tugas Selesai', '24'),
            _buildInfoRow(Icons.thumb_up, 'Ulasan Positif', '95%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: Colors.blue[800])),
          ),
        ],
      ),
    );
  }

  void _showRoleUpdateDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Role User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih role baru untuk ${user.namaLengkap}:'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: user.role,
              items: ['user', 'admin', 'volunteer']
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (newRole) {
                if (newRole != null) {
                  _updateUserRole(user.id, newRole);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.isVerified ? 'Batalkan Verifikasi' : 'Verifikasi User',
        ),
        content: Text(
          user.isVerified
              ? 'Apakah Anda yakin ingin membatalkan verifikasi ${user.namaLengkap}?'
              : 'Apakah Anda yakin ingin memverifikasi ${user.namaLengkap}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateVerificationStatus(user.id, !user.isVerified);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isVerified ? Colors.red : Colors.green,
            ),
            child: Text(user.isVerified ? 'Batalkan' : 'Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _updateUserRole(int userId, String newRole) async {
    try {
      await widget.userService.updateUserRole(userId, newRole);
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role berhasil diubah menjadi $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah role: $e')));
    }
  }

  void _updateVerificationStatus(int userId, bool isVerified) async {
    try {
      await widget.userService.updateVerificationStatus(userId, isVerified);
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status verifikasi berhasil diubah')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status verifikasi: $e')),
      );
    }
  }

  bool _isCurrentUserAdmin() {
    // Implement logic to check if current user is admin
    // This could be from shared preferences or state management
    return true; // Temporary
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

  String _formatDetailedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
