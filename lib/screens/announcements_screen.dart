// screens/announcements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/providers/auth_provider.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'my', 'important'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final announcementProvider = Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Set user ID dari auth provider
      if (authProvider.user?.id != null) {
        announcementProvider.setCurrentUserInfo(authProvider.user!.id);
      }

      // Load announcements dengan context
      announcementProvider.loadAnnouncements(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Announcement> _filterAnnouncements(List<Announcement> announcements) {
    List<Announcement> filtered = announcements;

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((announcement) {
        return announcement.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            announcement.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            announcement.targetAudience.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (announcement.admin?.namaLengkap.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Filter tambahan berdasarkan kategori
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    switch (_selectedFilter) {
      case 'my':
        filtered = filtered
            .where((announcement) => provider.isAnnouncementOwner(announcement))
            .toList();
        break;
      case 'important':
        filtered = filtered
            .where(
              (announcement) =>
                  announcement.targetAudience == 'ADMIN' ||
                  announcement.targetAudience == 'VOLUNTEER',
            )
            .toList();
        break;
      case 'all':
      default:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, child) {
        // Cek jika perlu login ulang
        if (provider.needsReLogin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showReLoginDialog(context);
          });
        }
        return Scaffold(
          backgroundColor: Color(0xFFF7F9FC),
          appBar: AppBar(
            title: Text(
              'Pengumuman',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E88E5),
            elevation: 1,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Color(0xFF1E88E5)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Color(0xFF1E88E5)),
                onPressed: () {
                  final provider = Provider.of<AnnouncementProvider>(
                    context,
                    listen: false,
                  );
                  provider.loadAnnouncements(context);
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              final filteredAnnouncements = _filterAnnouncements(
                provider.announcements,
              );

              return Column(
                children: [
                  // Search Bar dengan Filter
                  _buildSearchAndFilterSection(),

                  // Stats Info
                  if (!provider.isLoading && provider.announcements.isNotEmpty)
                    _buildStatsInfo(
                      provider.announcements.length,
                      filteredAnnouncements.length,
                    ),

                  // Content
                  Expanded(
                    child: _buildContent(provider, filteredAnnouncements),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              return FloatingActionButton(
                onPressed: provider.isCreating
                    ? null // ⬅️ Disable saat loading
                    : () => _showAddAnnouncementDialog(context),
                backgroundColor: provider.isCreating
                    ? Colors.grey[400] // ⬅️ Warna abu saat loading
                    : Color(0xFF1E88E5),
                child: provider.isCreating
                    ? SizedBox(
                        // ⬅️ Loading indicator di FAB
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.add, color: Colors.white, size: 28),
                elevation: 4,
                tooltip: provider.isCreating
                    ? 'Sedang membuat...'
                    : 'Buat Pengumuman',
              );
            },
          ),
        );
      },
    );
  }

  void _showReLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Sesi Berakhir'),
          ],
        ),
        content: Text(
          'Sesi Anda telah berakhir. Silakan login kembali untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate ke login screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E88E5)),
            child: Text('Login Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pengumuman...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                SizedBox(width: 8),
                _buildFilterChip('Pengumuman Saya', 'my'),
                SizedBox(width: 8),
                _buildFilterChip('Penting', 'important'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(0xFF1E88E5),
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF1E88E5),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Color(0xFF1E88E5) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildStatsInfo(int total, int filtered) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E88E5).withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF1E88E5)),
          SizedBox(width: 8),
          Text(
            filtered == total
                ? '$total pengumuman ditemukan'
                : '$filtered dari $total pengumuman ditemukan',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF1E88E5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AnnouncementProvider provider,
    List<Announcement> announcements,
  ) {
    if (provider.isLoading && provider.announcements.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (announcements.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty || _selectedFilter != 'all',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAnnouncements(context),
      color: Color(0xFF1E88E5),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _buildAnnouncementCard(announcement, context);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E88E5), strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Memuat pengumuman...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AnnouncementProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red),
            ),
            SizedBox(height: 20),
            Text(
              'Gagal memuat pengumuman',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              provider.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadAnnouncements(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilter) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.announcement_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 20),
            Text(
              hasFilter ? 'Tidak ada hasil' : 'Belum ada pengumuman',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Coba ubah pencarian atau filter'
                  : 'Pengumuman akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            if (hasFilter) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'all';
                    _searchController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Tampilkan Semua'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    Announcement announcement,
    BuildContext context,
  ) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    final isOwner = provider.isAnnouncementOwner(announcement);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Bisa ditambahkan detail view nanti
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  announcement.audienceColor.withOpacity(0.03),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Highlight side border
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: announcement.audienceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dengan badge dan actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  announcement.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: announcement.audienceColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: announcement.audienceColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    announcement.audienceText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: announcement.audienceColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOwner)
                            _buildOwnerActions(announcement, context),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Description
                      Text(
                        announcement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16),

                      // Metadata
                      Row(
                        children: [
                          _buildMetadataItem(
                            Icons.calendar_today,
                            announcement.formattedDate,
                          ),
                          SizedBox(width: 16),
                          _buildMetadataItem(Icons.schedule, announcement.day),
                          Spacer(),
                          _buildMetadataItem(
                            Icons.access_time,
                            announcement.timeAgo,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Author info
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  announcement.admin?.namaLengkap ?? 'Admin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Dibuat ${announcement.timeAgo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildOwnerActions(Announcement announcement, BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, child) {
        final isProcessing = provider.isUpdating || provider.isDeleting;

        return PopupMenuButton<String>(
          enabled: !isProcessing, // ⬅️ Disable saat processing
          icon: isProcessing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[500],
                  ),
                )
              : Icon(Icons.more_vert, color: Colors.grey[500]),
          onSelected: (value) =>
              _handleOwnerAction(value, announcement, context),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: Color(0xFF1E88E5)),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleOwnerAction(
    String action,
    Announcement announcement,
    BuildContext context,
  ) {
    Provider.of<AnnouncementProvider>(context, listen: false);

    switch (action) {
      case 'edit':
        _showEditAnnouncementDialog(context, announcement);
        break;
      case 'delete':
        _showDeleteDialog(announcement, context);
        break;
    }
  }

  void _showAddAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dayController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedAudience = 'ALL_RESIDENTS';

    String _getIndonesianDayName(DateTime date) {
      const days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      return days[date.weekday % 7];
    }

    dayController.text = _getIndonesianDayName(selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false, // ⬅️ Mencegah dialog ditutup saat loading
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 600),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E88E5).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.announcement,
                              color: Color(0xFF1E88E5),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Buat Pengumuman Baru',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          if (provider
                              .isCreating) // ⬅️ Tampilkan loading kecil di header
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Form Content atau Loading
                      if (!provider
                          .isCreating) // ⬅️ Tampilkan form jika TIDAK loading
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFormField(
                                  controller: titleController,
                                  label: 'Judul Pengumuman',
                                  hint: 'Masukkan judul pengumuman',
                                  maxLines: 1,
                                  icon: Icons.title,
                                ),
                                SizedBox(height: 16),

                                _buildFormField(
                                  controller: descriptionController,
                                  label: 'Deskripsi Pengumuman',
                                  hint: 'Tulis deskripsi pengumuman di sini...',
                                  maxLines: 4,
                                  icon: Icons.description,
                                ),
                                SizedBox(height: 16),

                                _buildDatePicker(
                                  selectedDate: selectedDate,
                                  onDateChanged: (date) {
                                    setState(() {
                                      selectedDate = date;
                                      dayController.text =
                                          _getIndonesianDayName(date);
                                    });
                                  },
                                ),
                                SizedBox(height: 16),

                                _buildFormField(
                                  controller: dayController,
                                  label: 'Hari',
                                  hint: 'Hari akan terisi otomatis',
                                  maxLines: 1,
                                  icon: Icons.calendar_view_day,
                                  readOnly: true,
                                ),
                                SizedBox(height: 16),

                                _buildAudienceDropdown(
                                  selectedAudience: selectedAudience,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => selectedAudience = value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      else // ⬅️ Tampilkan loading screen jika SEDANG loading
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF1E88E5),
                                  strokeWidth: 3,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Membuat pengumuman...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Mohon tunggu sebentar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 24),

                      // Action Buttons - Sembunyikan saat loading
                      if (!provider.isCreating)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (titleController.text.isEmpty) {
                                    _showWarningSnackbar(
                                      context,
                                      'Judul pengumuman harus diisi',
                                    );
                                    return;
                                  }

                                  if (descriptionController.text.isEmpty) {
                                    _showWarningSnackbar(
                                      context,
                                      'Deskripsi pengumuman harus diisi',
                                    );
                                    return;
                                  }

                                  try {
                                    final provider =
                                        Provider.of<AnnouncementProvider>(
                                          context,
                                          listen: false,
                                        );

                                    await provider.addAnnouncement(
                                      context: context,
                                      title: titleController.text,
                                      description: descriptionController.text,
                                      targetAudience: selectedAudience,
                                      date: selectedDate,
                                      day: dayController.text,
                                    );

                                    _showSuccessSnackbar(
                                      context,
                                      'Pengumuman berhasil dibuat',
                                    );

                                    Navigator.pop(context);
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      context,
                                      'Gagal membuat pengumuman: $e',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1E88E5),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Buat Pengumuman',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Color(0xFF1E88E5)),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: readOnly
                  ? Colors.grey[300]!
                  : Color(0xFF1E88E5).withOpacity(0.3),
            ),
            boxShadow: [
              if (!readOnly)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintStyle: TextStyle(
                color: readOnly ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            style: TextStyle(
              color: readOnly ? Colors.grey[600] : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required DateTime selectedDate,
    required Function(DateTime) onDateChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Color(0xFF1E88E5)),
            SizedBox(width: 6),
            Text(
              'Tanggal Pengumuman',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Color(0xFF1E88E5),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.grey[800]!,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != selectedDate) {
              onDateChanged(picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF1E88E5).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _getIndonesianDayName(
                        selectedDate,
                      ), // Tampilkan nama hari juga
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Color(0xFF1E88E5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceDropdown({
    required String selectedAudience,
    required Function(String?) onChanged,
    List<String>? rtOptions, // Tambahkan opsi RT jika tersedia
  }) {
    // Daftar target audience sesuai backend
    final List<Map<String, dynamic>> audienceOptions = [
      {
        'value': 'ALL_RESIDENTS',
        'label': 'Semua Warga',
        'icon': Icons.people,
        'color': Color(0xFF3B82F6),
      },
      {
        'value': 'VOLUNTEER',
        'label': 'Volunteer',
        'icon': Icons.volunteer_activism,
        'color': Colors.green,
      },
      {
        'value': 'ADMIN',
        'label': 'Admin',
        'icon': Icons.admin_panel_settings,
        'color': Colors.red,
      },
    ];

    // Tambahkan opsi RT jika ada
    if (rtOptions != null) {
      for (var rt in rtOptions) {
        audienceOptions.add({
          'value': 'RT_$rt',
          'label': 'RT $rt',
          'icon': Icons.home,
          'color': Colors.orange,
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group, size: 18, color: Color(0xFF1E88E5)),
            SizedBox(width: 6),
            Text(
              'Target Audience',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF1E88E5).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedAudience,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
            items: audienceOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: option['color'] as Color,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(option['label'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // Tambahkan fungsi helper untuk mendapatkan nama hari
  String _getIndonesianDayName(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return days[date.weekday % 7];
  }

  void _showEditAnnouncementDialog(
    BuildContext context,
    Announcement announcement,
  ) {
    final titleController = TextEditingController(text: announcement.title);
    final descriptionController = TextEditingController(
      text: announcement.description,
    );
    final dayController = TextEditingController(text: announcement.day);
    DateTime selectedDate = announcement.date;
    String selectedAudience = announcement.targetAudience;

    String _getIndonesianDayName(DateTime date) {
      const days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      return days[date.weekday % 7];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 600),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Edit
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edit Pengumuman',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          if (provider
                              .isUpdating) // ⬅️ Loading indicator di header
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Form atau Loading
                      if (!provider.isUpdating)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFormField(
                                  controller: titleController,
                                  label: 'Judul Pengumuman',
                                  hint: 'Masukkan judul pengumuman',
                                  maxLines: 1,
                                  icon: Icons.title,
                                ),
                                SizedBox(height: 16),
                                _buildFormField(
                                  controller: descriptionController,
                                  label: 'Deskripsi Pengumuman',
                                  hint: 'Tulis deskripsi pengumuman di sini...',
                                  maxLines: 4,
                                  icon: Icons.description,
                                ),
                                SizedBox(height: 16),
                                _buildDatePicker(
                                  selectedDate: selectedDate,
                                  onDateChanged: (date) {
                                    setState(() {
                                      selectedDate = date;
                                      dayController.text =
                                          _getIndonesianDayName(date);
                                    });
                                  },
                                ),
                                SizedBox(height: 16),
                                _buildFormField(
                                  controller: dayController,
                                  label: 'Hari',
                                  hint: 'Hari akan terisi otomatis',
                                  maxLines: 1,
                                  icon: Icons.calendar_view_day,
                                  readOnly: true,
                                ),
                                SizedBox(height: 16),
                                _buildAudienceDropdown(
                                  selectedAudience: selectedAudience,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => selectedAudience = value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.orange,
                                  strokeWidth: 3,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Memperbarui pengumuman...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),

                      // Action Buttons
                      if (!provider.isUpdating)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (titleController.text.isEmpty ||
                                      descriptionController.text.isEmpty) {
                                    _showWarningSnackbar(
                                      context,
                                      'Harap isi semua field yang wajib',
                                    );
                                    return;
                                  }

                                  try {
                                    final provider =
                                        Provider.of<AnnouncementProvider>(
                                          context,
                                          listen: false,
                                        );
                                    await provider.updateAnnouncement(
                                      context: context,
                                      id: announcement.id,
                                      title: titleController.text,
                                      description: descriptionController.text,
                                      targetAudience: selectedAudience,
                                      date: selectedDate,
                                      day: dayController.text,
                                    );
                                    _showSuccessSnackbar(
                                      context,
                                      'Pengumuman berhasil diupdate',
                                    );
                                    Navigator.pop(context);
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      context,
                                      'Gagal mengupdate pengumuman: $e',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Update Pengumuman',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Announcement announcement, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<AnnouncementProvider>(
          builder: (context, provider, child) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                child: provider.isDeleting
                    ? Column(
                        // ⬅️ Loading screen saat hapus
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Menghapus pengumuman...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        // ⬅️ Dialog konfirmasi normal
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning,
                              size: 32,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Hapus Pengumuman',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Apakah Anda yakin ingin menghapus pengumuman "${announcement.title}"? Tindakan ini tidak dapat dibatalkan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Batal'),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final provider =
                                          Provider.of<AnnouncementProvider>(
                                            context,
                                            listen: false,
                                          );
                                      await provider.deleteAnnouncement(
                                        id: announcement.id,
                                        context: context,
                                      );
                                      Navigator.pop(context);
                                      _showSuccessSnackbar(
                                        context,
                                        'Pengumuman berhasil dihapus',
                                      );
                                    } catch (e) {
                                      Navigator.pop(context);
                                      _showErrorSnackbar(
                                        context,
                                        'Gagal menghapus pengumuman: $e',
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Hapus'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
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

  void _showWarningSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
