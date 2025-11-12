// screens/announcements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      );
      provider.loadAnnouncements();
      // Set current user ID dari data login
      provider.setCurrentUserId(1); // Ganti dengan ID user yang login
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Announcement> _filterAnnouncements(List<Announcement> announcements) {
    if (_searchQuery.isEmpty) return announcements;

    return announcements.where((announcement) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Pengumuman'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<AnnouncementProvider>(
                context,
                listen: false,
              );
              provider.loadAnnouncements();
            },
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
              // Search Bar
              _buildSearchBar(),

              // Status Info
              if (!provider.isLoading && provider.announcements.isNotEmpty)
                _buildStatsInfo(
                  provider.announcements.length,
                  filteredAnnouncements.length,
                ),

              // Content
              Expanded(child: _buildContent(provider, filteredAnnouncements)),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AnnouncementProvider>(
        builder: (context, provider, child) {
          // Hanya tampilkan FAB jika user adalah admin (berdasarkan logic aplikasi)
          // Anda bisa menyesuaikan kondisi ini berdasarkan role user
          return FloatingActionButton(
            onPressed: () => _showAddAnnouncementDialog(context),
            backgroundColor: Colors.orange,
            child: Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
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
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildStatsInfo(int total, int filtered) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            filtered == total
                ? '$total pengumuman ditemukan'
                : '$filtered dari $total pengumuman ditemukan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[800],
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
      return _buildEmptyState(_searchQuery.isNotEmpty);
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAnnouncements(),
      color: Colors.orange,
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
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Memuat pengumuman...',
            style: TextStyle(color: Colors.grey[600]),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Gagal memuat pengumuman',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              provider.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.loadAnnouncements(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.announcement_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            isSearching ? 'Tidak ada hasil pencarian' : 'Belum ada pengumuman',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isSearching
                ? 'Coba dengan kata kunci lain'
                : 'Pengumuman akan muncul di sini',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    Announcement announcement,
    BuildContext context,
  ) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    final isOwner = provider.isAnnouncementOwner(announcement);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: announcement.audienceColor, width: 4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan title dan target audience
              Row(
                children: [
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: announcement.audienceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: announcement.audienceColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      announcement.audienceText,
                      style: TextStyle(
                        fontSize: 10,
                        color: announcement.audienceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Description
              Text(
                announcement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),

              // Date and Day Info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    announcement.formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.schedule, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    announcement.day,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Footer dengan author dan actions
              Row(
                children: [
                  // Author info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              announcement.admin?.namaLengkap ?? 'Admin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              announcement.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons untuk pemilik pengumuman
                  if (isOwner) _buildOwnerActions(announcement, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerActions(Announcement announcement, BuildContext context) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) => _handleOwnerAction(value, announcement, context),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.blue),
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
  }

  void _handleOwnerAction(
    String action,
    Announcement announcement,
    BuildContext context,
  ) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);

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
    String selectedAudience = 'ALL';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Buat Pengumuman Baru'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Pengumuman',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 1,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Pengumuman',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 12),
                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: dayController,
                    decoration: InputDecoration(
                      labelText: 'Hari (contoh: Senin, Selasa, dll)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedAudience,
                    decoration: InputDecoration(
                      labelText: 'Target Audience',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'ALL', child: Text('Semua User')),
                      DropdownMenuItem(
                        value: 'VOLUNTEER',
                        child: Text('Volunteer'),
                      ),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedAudience = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty &&
                      dayController.text.isNotEmpty) {
                    try {
                      final provider = Provider.of<AnnouncementProvider>(
                        context,
                        listen: false,
                      );
                      await provider.addAnnouncement(
                        title: titleController.text,
                        description: descriptionController.text,
                        targetAudience: selectedAudience,
                        date: selectedDate,
                        day: dayController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pengumuman berhasil dibuat'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuat pengumuman: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Harap isi semua field'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Pengumuman'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Pengumuman',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Pengumuman',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: dayController,
                    decoration: InputDecoration(
                      labelText: 'Hari',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedAudience,
                    decoration: InputDecoration(
                      labelText: 'Target Audience',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'ALL', child: Text('Semua User')),
                      DropdownMenuItem(
                        value: 'VOLUNTEER',
                        child: Text('Volunteer'),
                      ),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedAudience = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty &&
                      dayController.text.isNotEmpty) {
                    try {
                      final provider = Provider.of<AnnouncementProvider>(
                        context,
                        listen: false,
                      );
                      await provider.updateAnnouncement(
                        id: announcement.id,
                        title: titleController.text,
                        description: descriptionController.text,
                        targetAudience: selectedAudience,
                        date: selectedDate,
                        day: dayController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pengumuman berhasil diupdate'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal mengupdate pengumuman: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Announcement announcement, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Pengumuman'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengumuman "${announcement.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final provider = Provider.of<AnnouncementProvider>(
                  context,
                  listen: false,
                );
                await provider.deleteAnnouncement(announcement.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pengumuman berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus pengumuman: $e'),
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
}
