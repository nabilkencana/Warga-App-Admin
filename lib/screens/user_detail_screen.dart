// screens/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wargaapp_admin/models/user.dart';
import 'package:wargaapp_admin/services/user_service.dart'; // ✅ FIXED

class UserDetailScreen extends StatefulWidget {
  final int userId;
  final UserService userService = UserService();

  UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;
  final ImagePicker _picker = ImagePicker();
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final user = await widget.userService.getUserById(widget.userId);

      Map<String, int> stats;
      try {
        stats = await widget.userService.getUserStats(widget.userId);
        print('Stats loaded successfully: $stats');
      } catch (e) {
        print('Error loading stats: $e');
        stats = user.getStats();
        print('Using fallback stats from user object: $stats');
      }

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
            onPressed: () => _showEditDialog(context),
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

                // 🎯 KK Document Section
                _buildKKDocumentSection(user),
                SizedBox(height: 24),

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

  // 🎯 KK Document Section - FIXED
  Widget _buildKKDocumentSection(User user) {
    final hasKKFile = user.kkFileUrl != null && user.kkFileUrl!.isNotEmpty;
    final kkVerificationStatus =
        user.kkVerificationStatus ?? 'pending'; // ✅ FIXED

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getKKStatusColor(
                      kkVerificationStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getKKStatusColor(kkVerificationStatus),
                    ),
                  ),
                  child: Text(
                    _getKKStatusText(kkVerificationStatus),
                    style: TextStyle(
                      color: _getKKStatusColor(kkVerificationStatus),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (hasKKFile)
              Column(
                children: [
                  // KK File Preview
                  _buildKKFilePreview(user),
                  SizedBox(height: 16),

                  // Status Info
                  if (kkVerificationStatus == 'rejected' &&
                      user.kkRejectionReason != null) // ✅ FIXED
                    _buildRejectionReason(user.kkRejectionReason!),

                  if (kkVerificationStatus == 'verified' &&
                      user.kkVerifiedAt != null) // ✅ FIXED
                    _buildVerificationInfo(
                      user.kkVerifiedAt!,
                      user.kkVerifiedBy,
                    ),

                  SizedBox(height: 16),

                  // Verification Actions for Admin
                  if (_isCurrentUserAdmin() &&
                      kkVerificationStatus != 'verified')
                    _buildKKAdminActions(user),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!), // ✅ FIXED
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada dokumen KK',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload dokumen KK untuk verifikasi akun',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Upload Button for current user
                  if (_isCurrentUser(user.id))
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUploadKK(user),
                        icon: Icon(Icons.upload),
                        label: Text('Upload KK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 🎯 Rejection Reason Widget - FIXED
  Widget _buildRejectionReason(String reason) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!), // ✅ FIXED
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text(
                'Dokumen Ditolak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Alasan: $reason',
            style: TextStyle(color: Colors.red[700], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // 🎯 Verification Info Widget - FIXED
  Widget _buildVerificationInfo(DateTime verifiedAt, int? verifiedBy) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[100]!), // ✅ FIXED
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text(
                'Dokumen Terverifikasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Terverifikasi pada ${_formatDate(verifiedAt)}',
            style: TextStyle(color: Colors.green[700], fontSize: 12),
          ),
          if (verifiedBy != null)
            Text(
              'Oleh: $verifiedBy',
              style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
        ],
      ),
    );
  }

  // 🎯 Open in Browser Method - FIXED
  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        // ✅ FIXED: gunakan canLaunchUrl
        await launchUrl(uri); // ✅ FIXED: gunakan launchUrl
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka URL')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ============ TIDAK BERUBAH (sisa kode tetap sama) ============
  // [Kode lainnya tetap sama seperti sebelumnya...]

  Widget _buildKKFilePreview(User user) {
    final kkUrl = user.kkFileUrl!;
    final isImage = _isImageFile(kkUrl);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showKKDocumentPreview(kkUrl),
          child: Container(
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
                  : _buildGenericFilePreview(),
            ),
          ),
        ),
        SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove_red_eye, color: Colors.blue[800]),
              onPressed: () => _showKKDocumentPreview(kkUrl),
              tooltip: 'Lihat',
            ),
            IconButton(
              icon: Icon(Icons.open_in_new, color: Colors.blue[800]),
              onPressed: () => _openInBrowser(kkUrl),
              tooltip: 'Buka di Browser',
            ),
            IconButton(
              icon: Icon(Icons.download, color: Colors.blue[800]),
              onPressed: () => _downloadKKDocument(kkUrl),
              tooltip: 'Download',
            ),
            if (_isCurrentUser(user.id))
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteKKDialog(user),
                tooltip: 'Hapus',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => _buildErrorPreview(),
        ),
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

  Widget _buildGenericFilePreview() {
    return Center(
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

  Widget _buildKKAdminActions(User user) {
    return Column(
      children: [
        Divider(),
        SizedBox(height: 16),
        Text(
          'Verifikasi Admin',
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
              child: ElevatedButton.icon(
                onPressed: () => _rejectKKDocument(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(Icons.close, size: 18),
                label: Text('Tolak'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveKKDocument(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[50],
                  foregroundColor: Colors.green,
                  side: BorderSide(color: Colors.green),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(Icons.verified, size: 18),
                label: Text('Setujui'),
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

  void _showKKDocumentPreview(String url) {
    if (_isImageFile(url)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.8)),
              ),
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
                ),
              ),
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
    } else {
      _openInBrowser(url);
    }
  }

  void _downloadKKDocument(String url) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Fitur download belum tersedia')));
  }

  Future<void> _pickAndUploadKK(User user) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Upload Dokumen KK'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengupload dokumen KK...'),
              ],
            ),
          ),
        );

        try {
          await widget.userService.uploadKKDocument(
            userId: user.id,
            filePath: pickedFile.path,
          );

          Navigator.pop(context);
          _refreshData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dokumen KK berhasil diupload'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal upload: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showDeleteKKDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Dokumen KK'),
        content: Text('Apakah Anda yakin ingin menghapus dokumen KK ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.userService.deleteKKDocument(user.id);
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dokumen KK berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _approveKKDocument(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setujui Dokumen KK'),
        content: Text('Apakah Anda yakin menyetujui dokumen KK ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.userService.verifyKKDocument(
                  userId: user.id,
                  isApproved: true,
                );
                Navigator.pop(context);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dokumen KK disetujui'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _rejectKKDocument(User user) {
    final _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Dokumen KK'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berikan alasan penolakan:'),
            SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Foto tidak jelas, data tidak sesuai...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _reasonController.text.isEmpty
                ? null
                : () async {
                    try {
                      await widget.userService.verifyKKDocument(
                        userId: user.id,
                        isApproved: false,
                        rejectionReason: _reasonController.text,
                      );
                      Navigator.pop(context);
                      _refreshData();
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
                          content: Text('Gagal: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            child: Text('Tolak'),
          ),
        ],
      ),
    );
  }

  bool _isImageFile(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return imageExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  Color _getKKStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getKKStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'TERVERIFIKASI';
      case 'rejected':
        return 'DITOLAK';
      default:
        return 'MENUNGGU';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isCurrentUser(int userId) {
    // TODO: Implement user ID dari shared preferences
    return false;
  }

  // ============ EXISTING METHODS (tidak berubah) ============

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
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan overflow handling
                  Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kirim Pesan ke ${user.namaLengkap}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Subtitle informasi penerima
                  if (user.nomorTelepon != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(
                        'Ke: ${user.nomorTelepon}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Form pesan
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Isi Pesan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan Anda di sini...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 6,
                          minLines: 4,
                          maxLength: 500,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Pesan tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_messageController.text.length}/500 karakter',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'BATAL',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              try {
                                // Tampilkan loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Simulasi delay pengiriman
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );

                                Navigator.pop(context); // Tutup loading
                                Navigator.pop(context); // Tutup dialog pesan

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Pesan berhasil dikirim'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(
                                  context,
                                ); // Tutup loading jika error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Gagal mengirim: ${e.toString()}'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'KIRIM',
                            style: TextStyle(fontWeight: FontWeight.w500),
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
    // Convert string role ke enum value jika perlu
    String? selectedRole = _convertRoleToString(user.role);
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ubah Role User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Mengubah role untuk '),
                      TextSpan(
                        text: user.namaLengkap,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const TextSpan(text: '.\nRole saat ini: '),
                      TextSpan(
                        text: _formatRoleName(user.role),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Role Baru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: [
                          _buildRoleItem(
                            'USER',
                            'User Biasa',
                            Icons.person_outline,
                          ),
                          _buildRoleItem(
                            'ADMIN',
                            'Administrator',
                            Icons.admin_panel_settings,
                          ),
                          _buildRoleItem(
                            'SUPER_ADMIN',
                            'Super Admin',
                            Icons.security,
                          ),
                          _buildRoleItem(
                            'SATPAM',
                            'Satpam',
                            Icons.security_outlined,
                          ),
                          // _buildRoleItem(
                          //   'VOLUNTEER',
                          //   'Relawan',
                          //   Icons.volunteer_activism,
                          // ),
                        ],
                        onChanged: _isUpdating
                            ? null
                            : (newRole) {
                                setState(() {
                                  selectedRole = newRole;
                                });
                              },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[500],
                        ),
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedRole != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRoleColor(selectedRole!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRoleColor(selectedRole!).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getRoleIcon(selectedRole!),
                          color: _getRoleColor(selectedRole!),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getRoleDescription(selectedRole!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isUpdating ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                // Di dalam onPressed di _showRoleUpdateDialog:
                onPressed: _isUpdating || selectedRole == null
                    ? null
                    : () async {
                        final currentRole = _convertRoleToString(user.role);
                        if (selectedRole == currentRole) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Role sudah ${_formatRoleName(selectedRole!)}',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }

                        setState(() => _isUpdating = true);

                        try {
                          // Gunakan userService yang sudah ada atau buat instance baru
                          final userService = UserService();

                          // Panggil fungsi update role dari service
                          await userService.updateUserRole(
                            user.id,
                            selectedRole!,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);

                            // Refresh data user
                            await _loadUserData();

                            // Refresh data user setelah update
                            // Tergantung bagaimana Anda mengelola state di screen ini

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Role ${user.namaLengkap} berhasil diubah ke ${_formatRoleName(selectedRole!)}',
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _isUpdating = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Gagal mengubah role: ${e.toString()}',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isUpdating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SIMPAN'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  // Helper functions
  DropdownMenuItem<String> _buildRoleItem(
    String value,
    String label,
    IconData icon,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: _getRoleColor(value)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }

  String _convertRoleToString(dynamic role) {
    if (role == null) return 'USER';
    if (role is String) return role;
    return role.toString();
  }

  String _formatRoleName(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Admin';
      case 'SATPAM':
        return 'Satpam';
      case 'VOLUNTEER':
        return 'Relawan';
      default:
        return 'User';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return Colors.purple;
      case 'ADMIN':
        return Colors.blue;
      case 'SATPAM':
        return Colors.orange;
      case 'VOLUNTEER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return Icons.security;
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'SATPAM':
        return Icons.security_outlined;
      case 'VOLUNTEER':
        return Icons.volunteer_activism;
      default:
        return Icons.person_outline;
    }
  }

  String _getRoleDescription(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'Akses penuh ke semua fitur dan sistem';
      case 'ADMIN':
        return 'Dapat mengelola user, konten, dan laporan';
      case 'SATPAM':
        return 'Dapat mengelola keamanan dan akses area';
      case 'VOLUNTEER':
        return 'Dapat membantu kegiatan dan laporan tertentu';
      default:
        return 'Akses terbatas untuk fitur umum';
    }
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
            child: Text(user.isVerified ? 'Batalkan' : 'Verifikasi' , style: TextStyle(color: Colors.white),),
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
            child: Text('Hapus' , style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
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
    // TODO: Implement admin check dari shared preferences
    return true;
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
