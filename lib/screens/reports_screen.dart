// screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ReportProvider>(context, listen: false);
      provider.loadReports();
      // Set current user ID dari data login
      provider.setCurrentUserId(1); // Ganti dengan ID user yang login
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Report> _searchReports(List<Report> reports) {
    if (_searchQuery.isEmpty) return reports;

    return reports.where((report) {
      return report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          report.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Laporan Masyarakat'),
        backgroundColor: Colors.purple,
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
              final provider = Provider.of<ReportProvider>(
                context,
                listen: false,
              );
              provider.loadReports();
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, child) {
          final searchedReports = _searchReports(provider.reports);

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(),

              // Quick Stats
              if (!provider.isLoading && provider.reports.isNotEmpty)
                _buildQuickStats(provider),

              // Filter Chips
              _buildFilterSection(provider),

              // Content
              Expanded(child: _buildContent(provider, searchedReports)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateReportDialog(context),
        backgroundColor: Colors.purple,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari laporan...',
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

  Widget _buildQuickStats(ReportProvider provider) {
    final stats = provider.getReportStats();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total']!.toString(), Icons.assessment),
          _buildStatItem(
            'Pending',
            stats['pending']!.toString(),
            Icons.pending_actions,
          ),
          _buildStatItem(
            'Diproses',
            stats['in_progress']!.toString(),
            Icons.autorenew,
          ),
          _buildStatItem(
            'Selesai',
            stats['completed']!.toString(),
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildFilterSection(ReportProvider provider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Berdasarkan:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          // Status Filter
          Wrap(
            spacing: 8,
            children: provider.statusFilters.map((filter) {
              return FilterChip(
                label: Text(filter),
                selected: provider.selectedFilter == filter,
                onSelected: (selected) => provider.setFilter(filter),
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.purple.withOpacity(0.2),
                checkmarkColor: Colors.purple,
                labelStyle: TextStyle(
                  color: provider.selectedFilter == filter
                      ? Colors.purple
                      : Colors.grey[700],
                  fontWeight: provider.selectedFilter == filter
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          // Category Filter
          Wrap(
            spacing: 8,
            children: provider.categoryFilters.map((category) {
              return FilterChip(
                label: Text(category),
                selected: provider.selectedCategory == category,
                onSelected: (selected) => provider.setCategory(category),
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: provider.selectedCategory == category
                      ? Colors.blue
                      : Colors.grey[700],
                  fontWeight: provider.selectedCategory == category
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReportProvider provider, List<Report> reports) {
    if (provider.isLoading && provider.reports.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (reports.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty ||
            provider.selectedFilter != 'Semua' ||
            provider.selectedCategory != 'Semua',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReports(),
      color: Colors.purple,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report, context);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 16),
          Text('Memuat laporan...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReportProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Gagal memuat laporan',
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
              onPressed: () => provider.loadReports(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak ada hasil' : 'Belum ada laporan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Laporan dari masyarakat akan muncul di sini',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report, BuildContext context) {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    final canEdit = provider.canEditReport(report);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showReportDetails(context, report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan status dan category
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      report.categoryIcon,
                      size: 16,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.categoryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: report.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: report.statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      report.statusText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: report.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Title
              Text(
                report.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),

              // Description
              Text(
                report.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),

              // Image preview jika ada
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(report.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Footer dengan waktu dan actions
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    report.timeAgo,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Spacer(),
                  if (report.userId != null) ...[
                    Icon(Icons.person_outline, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'User #${report.userId}',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (canEdit) _buildActionMenu(report, context),
                ],
              ),

              // Progress bar untuk status
              if (report.status != 'COMPLETED' && report.status != 'REJECTED')
                SizedBox(height: 12),
              if (report.status != 'COMPLETED' && report.status != 'REJECTED')
                _buildProgressBar(report.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(Report report, BuildContext context) {
    final provider = Provider.of<ReportProvider>(context, listen: false);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 16, color: Colors.grey),
      onSelected: (value) => _handleAction(value, report, context),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.update, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('Ubah Status'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, Report report, BuildContext context) {
    switch (action) {
      case 'edit':
        _showEditReportDialog(context, report);
        break;
      case 'status':
        _showStatusDialog(context, report);
        break;
      case 'delete':
        _showDeleteDialog(context, report);
        break;
    }
  }

  Widget _buildProgressBar(String status) {
    double progress = 0.0;
    if (status == 'PENDING') progress = 0.3;
    if (status == 'IN_PROGRESS') progress = 0.7;
    if (status == 'COMPLETED') progress = 1.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: Colors.purple,
          borderRadius: BorderRadius.circular(4),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Umum';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_comment, color: Colors.purple),
                SizedBox(width: 8),
                Text('Buat Laporan Baru'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Laporan',
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
                      labelText: 'Deskripsi Lengkap',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                          'Umum',
                          'Infrastruktur',
                          'Sampah',
                          'Keamanan',
                          'Kesehatan',
                          'Lingkungan',
                        ].map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value!),
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
                      descriptionController.text.isNotEmpty) {
                    try {
                      final provider = Provider.of<ReportProvider>(
                        context,
                        listen: false,
                      );
                      await provider.createReport(
                        title: titleController.text,
                        description: descriptionController.text,
                        category: selectedCategory,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Laporan berhasil dibuat'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuat laporan: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Harap isi semua field yang diperlukan'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text('Kirim Laporan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditReportDialog(BuildContext context, Report report) {
    final titleController = TextEditingController(text: report.title);
    final descriptionController = TextEditingController(
      text: report.description,
    );
    String selectedCategory = report.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Laporan'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Laporan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                          'Umum',
                          'Infrastruktur',
                          'Sampah',
                          'Keamanan',
                          'Kesehatan',
                          'Lingkungan',
                        ].map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value!),
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
                      descriptionController.text.isNotEmpty) {
                    try {
                      final provider = Provider.of<ReportProvider>(
                        context,
                        listen: false,
                      );
                      await provider.updateReport(
                        id: report.id,
                        title: titleController.text,
                        description: descriptionController.text,
                        category: selectedCategory,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Laporan berhasil diupdate'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal mengupdate laporan: $e'),
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

  void _showStatusDialog(BuildContext context, Report report) {
    String selectedStatus = report.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.update, color: Colors.orange),
                SizedBox(width: 8),
                Text('Ubah Status Laporan'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pilih status baru untuk laporan:'),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'PENDING', child: Text('Menunggu')),
                    DropdownMenuItem(
                      value: 'IN_PROGRESS',
                      child: Text('Diproses'),
                    ),
                    DropdownMenuItem(
                      value: 'COMPLETED',
                      child: Text('Selesai'),
                    ),
                    DropdownMenuItem(value: 'REJECTED', child: Text('Ditolak')),
                  ],
                  onChanged: (value) => setState(() => selectedStatus = value!),
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
                    final provider = Provider.of<ReportProvider>(
                      context,
                      listen: false,
                    );
                    await provider.updateReportStatus(
                      report.id,
                      selectedStatus,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status berhasil diubah'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengubah status: $e'),
                        backgroundColor: Colors.red,
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

  void _showDeleteDialog(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Laporan'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus laporan "${report.title}"? Tindakan ini tidak dapat dibatalkan.',
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
                final provider = Provider.of<ReportProvider>(
                  context,
                  listen: false,
                );
                await provider.deleteReport(report.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Laporan berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus laporan: $e'),
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

  void _showReportDetails(BuildContext context, Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Detail Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: report.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: report.statusColor),
                        ),
                        child: Text(
                          report.statusText.toUpperCase(),
                          style: TextStyle(
                            color: report.statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Title
                      Text(
                        report.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),

                      // Category
                      Row(
                        children: [
                          Icon(
                            report.categoryIcon,
                            size: 16,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            report.categoryText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Description
                      Text(
                        'Deskripsi:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        report.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Image jika ada
                      if (report.imageUrl != null &&
                          report.imageUrl!.isNotEmpty) ...[
                        Text(
                          'Gambar:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(report.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // User Info
                      if (report.userId != null) ...[
                        Text(
                          'Informasi Pelapor:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'User ID: ${report.userId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],

                      // Timestamps
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dibuat:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year} ${report.createdAt.hour}:${report.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diupdate:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${report.updatedAt.day}/${report.updatedAt.month}/${report.updatedAt.year} ${report.updatedAt.hour}:${report.updatedAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
              ),
            ],
          ),
        );
      },
    );
  }
}
