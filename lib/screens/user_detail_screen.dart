// screens/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final user = await widget.userService.getUserById(widget.userId);
      _currentUser = user;

      Map<String, int> stats;

      // Coba ambil statistik dari service
      try {
        stats = await widget.userService.getUserStats(widget.userId);
        print('Stats loaded successfully: $stats');
      } catch (e) {
        print('Error loading stats: $e');
        // Fallback ke data dari user object
        stats = user.getStats();
        print('Using fallback stats from user object: $stats');
      }

      // Debug final stats
      print('=== FINAL STATS ===');
      print('Laporan: ${stats['laporan']}');
      print('Darurat: ${stats['darurat']}');
      print('Aktivitas: ${stats['aktivitas']}');
      print('===================');

      return {'user': user, 'stats': stats, 'error': null};
    } catch (e) {
      print('Error loading user data: $e');
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

                // 🎯 NEW: KK Document Section - TAMBAHKAN DI SINI
                if (user.kkFileUrl != null) _buildKKDocumentSection(user),
                if (user.kkFileUrl != null) SizedBox(height: 24),

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

  // 🎯 NEW: KK Document Section Widget - TAMBAHKAN METHOD INI
  Widget _buildKKDocumentSection(User user) {
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
                Icon(Icons.description, color: Colors.blue[800], size: 20),
                SizedBox(width: 8),
                Text(
                  'Dokumen KK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(width: 8),
                if (!user.isVerified)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      'PERLU VERIFIKASI',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // KK File Preview
            _buildKKFilePreview(user),
            SizedBox(height: 16),

            // Verification Actions for Admin
            if (_isCurrentUserAdmin()) _buildKKVerificationActions(user),
          ],
        ),
      ),
    );
  }

  // 🎯 NEW: KK File Preview Widget
  Widget _buildKKFilePreview(User user) {
    final kkUrl = user.kkFileUrl!;
    final isImage = _isImageFile(kkUrl);
    final isPdf = _isPdfFile(kkUrl);

    return Column(
      children: [
        // File Preview
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isImage
                ? _buildImagePreview(kkUrl)
                : isPdf
                ? _buildPdfPreview(kkUrl)
                : _buildGenericFilePreview(kkUrl),
          ),
        ),
        SizedBox(height: 12),

        // File Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File KK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getFileType(kkUrl),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.open_in_new, color: Colors.blue[800]),
              onPressed: () => _openKKFile(kkUrl),
              tooltip: 'Buka file',
            ),
          ],
        ),
      ],
    );
  }

  // 🎯 Image Preview
  Widget _buildImagePreview(String imageUrl) {
    return Stack(
      children: [
        // Cached Network Image for better performance
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => _buildErrorPreview(),
        ),
        // Zoom button
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.zoom_in, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // 🎯 PDF Preview
  Widget _buildPdfPreview(String pdfUrl) {
    return GestureDetector(
      onTap: () => _openKKFile(pdfUrl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
          SizedBox(height: 8),
          Text(
            'Dokumen PDF',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap untuk membuka',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // 🎯 Generic File Preview
  Widget _buildGenericFilePreview(String fileUrl) {
    return GestureDetector(
      onTap: () => _openKKFile(fileUrl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
          SizedBox(height: 8),
          Text(
            'Dokumen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap untuk membuka',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // 🎯 Error Preview
  Widget _buildErrorPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text('Gagal memuat file', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  // 🎯 KK Verification Actions for Admin
  Widget _buildKKVerificationActions(User user) {
    return Column(
      children: [
        Divider(),
        SizedBox(height: 12),
        Text(
          'Verifikasi Dokumen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showKKRejectionDialog(user),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.red),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Tolak', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _verifyKKDocument(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Setujui', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Pastikan dokumen KK sesuai dan jelas sebelum verifikasi',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 🎯 Helper Methods
  bool _isImageFile(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return imageExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  bool _isPdfFile(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  String _getFileType(String url) {
    if (_isImageFile(url)) return 'Gambar';
    if (_isPdfFile(url)) return 'Dokumen PDF';
    return 'File';
  }

  // 🎯 Open KK File
  void _openKKFile(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Background overlay
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isImageFile(url))
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: InteractiveViewer(
                        panEnabled: true,
                        scaleEnabled: true,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) =>
                              _buildErrorPreview(),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 300,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPdfFile(url)
                                ? Icons.picture_as_pdf
                                : Icons.insert_drive_file,
                            size: 64,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Buka di Browser',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'File akan dibuka di browser eksternal',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Batal'),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement open in browser
                                  // _launchUrl(url);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Membuka file...')),
                                  );
                                },
                                child: Text('Buka'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 KK Verification Methods
  void _verifyKKDocument(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8),
            Text('Verifikasi Dokumen KK'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin memverifikasi dokumen KK ini?'),
            SizedBox(height: 8),
            Text(
              'Dokumen akan disetujui dan user akan mendapatkan akses penuh.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.userService.updateVerificationStatus(
                  user.id,
                  true,
                );
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dokumen KK berhasil diverifikasi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memverifikasi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _showKKRejectionDialog(User user) {
    final _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.close, color: Colors.red),
            SizedBox(width: 8),
            Text('Tolak Dokumen KK'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alasan penolakan:'),
            SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Foto tidak jelas, dokumen tidak sesuai...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harap berikan alasan penolakan';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_reasonController.text.isNotEmpty) {
                try {
                  // TODO: Implement rejection logic
                  // await widget.userService.rejectKKDocument(user.id, _reasonController.text);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dokumen KK ditolak'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menolak dokumen: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Tolak'),
          ),
        ],
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
                  stats['laporan']?.toString() ?? '0',
                  Icons.report,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Darurat',
                  stats['darurat']?.toString() ?? '0',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Aktivitas',
                  stats['aktivitas']?.toString() ?? '0',
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
                  _showMessageDialog(context, user);
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
          SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              _showDeleteConfirmationDialog(context, user);
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.red),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Hapus Akun', style: TextStyle(color: Colors.red)),
              ],
            ),
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

  // Di dalam _showEditDialog method, tambahkan field baru:
  void _showEditDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _namaController = TextEditingController(
      text: _currentUser.namaLengkap,
    );
    final _emailController = TextEditingController(text: _currentUser.email);
    final _bioController = TextEditingController(text: _currentUser.bio ?? '');
    final _phoneController = TextEditingController(
      text: _currentUser.nomorTelepon ?? '',
    );
    final _addressController = TextEditingController(
      text: _currentUser.alamat ?? '',
    );
    final _cityController = TextEditingController(
      text: _currentUser.kota ?? '',
    );
    final _nikController = TextEditingController(text: _currentUser.nik ?? '');
    final _instagramController = TextEditingController(
      text: _currentUser.instagram ?? '',
    );
    final _facebookController = TextEditingController(
      text: _currentUser.facebook ?? '',
    );

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
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lengkap harus diisi';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email harus diisi';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _nikController,
                  decoration: InputDecoration(
                    labelText: 'NIK',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'Instagram',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _facebookController,
                  decoration: InputDecoration(
                    labelText: 'Facebook',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Kota',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final updateData = {
                    'namaLengkap': _namaController.text,
                    'email': _emailController.text,
                    'bio': _bioController.text.isNotEmpty
                        ? _bioController.text
                        : null,
                    'nomorTelepon': _phoneController.text.isNotEmpty
                        ? _phoneController.text
                        : null,
                    'alamat': _addressController.text.isNotEmpty
                        ? _addressController.text
                        : null,
                    'kota': _cityController.text.isNotEmpty
                        ? _cityController.text
                        : null,
                    'nik': _nikController.text.isNotEmpty
                        ? _nikController.text
                        : null,
                    'instagram': _instagramController.text.isNotEmpty
                        ? _instagramController.text
                        : null,
                    'facebook': _facebookController.text.isNotEmpty
                        ? _facebookController.text
                        : null,
                  };

                  // Remove null values
                  updateData.removeWhere((key, value) => value == null);

                  await widget.userService.updateUserProfile(
                    _currentUser.id,
                    updateData,
                  );
                  _refreshData();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile berhasil diperbarui')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui profile: $e')),
                  );
                }
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context, User user) {
    final _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: Colors.blue[800]),
            SizedBox(width: 8),
            Text('Kirim Pesan ke ${user.namaLengkap}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Pesan',
                border: OutlineInputBorder(),
                hintText: 'Ketik pesan Anda di sini...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pesan tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (user.nomorTelepon != null)
              Text(
                'Pesan akan dikirim ke: ${user.nomorTelepon}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_messageController.text.isNotEmpty) {
                try {
                  // Implementasi pengiriman pesan sesuai dengan service yang tersedia
                  // Untuk sementara, kita simpan sebagai log
                  print(
                    'Mengirim pesan ke user ${user.id}: ${_messageController.text}',
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pesan berhasil dikirim')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengirim pesan: $e')),
                  );
                }
              }
            },
            child: Text('Kirim'),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hubungi $phoneNumber?'),
                  SizedBox(height: 8),
                  Text(
                    'Fitur ini akan membuka aplikasi telepon default Anda',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
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
                // Implementasi panggilan telepon
                // Untuk sementara, kita log saja
                print('Memanggil: $phoneNumber');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Membuka aplikasi telepon...')),
                );
              },
              child: Text('Hubungi'),
            ),
        ],
      ),
    );
  }

  void _showRoleUpdateDialog(BuildContext context, User user) {
    String? selectedRole = user.role;

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
              value: selectedRole,
              items: ['user', 'admin', 'volunteer']
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (newRole) {
                selectedRole = newRole;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedRole != null) {
                _updateUserRole(user.id, selectedRole!);
                Navigator.pop(context);
              }
            },
            child: Text('Simpan'),
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

  void _showDeleteConfirmationDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Akun'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus akun ${user.namaLengkap}?'),
            SizedBox(height: 8),
            Text(
              'Tindakan ini tidak dapat dibatalkan. Semua data user akan dihapus permanen.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteUserAccount(user.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
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

  void _deleteUserAccount(int userId) async {
    try {
      await widget.userService.deleteUser(userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Akun berhasil dihapus')));
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus akun: $e')));
    }
  }

  bool _isCurrentUserAdmin() {
    // Implementasi logika untuk mengecek apakah user saat ini adalah admin
    // Ini bisa dari shared preferences atau state management
    // Untuk sementara return true untuk testing
    return true;
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
