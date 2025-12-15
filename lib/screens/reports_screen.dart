// screens/reports_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  Map<String, dynamic>? _reportStats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('file://')) {
      return FileImage(File(imageUrl.replaceFirst('file://', '')));
    } else if (imageUrl.startsWith('/')) {
      return NetworkImage('${ReportProvider.imageBaseUrl}$imageUrl');
    } else {
      return FileImage(File(imageUrl));
    }
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('/')) {
      final fullUrl = imageUrl.startsWith('/')
          ? '${ReportProvider.imageBaseUrl}$imageUrl'
          : imageUrl;

      return Image.network(
        fullUrl,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.purple,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else {
      // Handle local file
      String filePath = imageUrl.startsWith('file://')
          ? imageUrl.replaceFirst('file://', '')
          : imageUrl;

      return Image.file(
        File(filePath),
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      height: 250,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Gagal memuat gambar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeData() async {
    try {
      final provider = Provider.of<ReportProvider>(context, listen: false);
      await provider.loadReports(refresh: true);

      // Load statistics
      final stats = await provider.getStatistics();
      setState(() {
        _reportStats = stats;
      });

      provider.setCurrentUserId(1); // Ganti dengan ID user yang login
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data awal: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;

    final provider = Provider.of<ReportProvider>(context, listen: false);
    if (!provider.hasMore || provider.isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      if (_searchQuery.isNotEmpty) {
        await provider.searchReports(_searchQuery);
      } else if (provider.selectedCategory != 'Semua') {
        await provider.loadReportsByCategory(provider.selectedCategory);
      } else if (provider.selectedFilter != 'Semua') {
        await provider.loadReportsByStatus(provider.selectedFilter);
      } else {
        await provider.loadReports();
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data tambahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Report> _searchReports(List<Report> reports) {
    if (_searchQuery.isEmpty) return reports;

    return reports.where((report) {
      return (report.title).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (report.description).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (report.category).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      final provider = Provider.of<ReportProvider>(context, listen: false);
      await provider.refreshData(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // Refresh statistics
      final stats = await provider.getStatistics();
      setState(() {
        _reportStats = stats;
      });
    } catch (e) {
      _showErrorSnackbar('Gagal menyegarkan data: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Laporan Masyarakat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Muat Ulang',
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
              if (!provider.isLoading &&
                  (provider.reports.isNotEmpty || _reportStats != null))
                // _buildQuickStats(provider),

              // Filter Section
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
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari judul, deskripsi, atau kategori laporan...',
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _refreshData();
                    },
                    tooltip: 'Hapus Pencarian',
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchQuery == value) {
                _refreshData();
              }
            });
          },
        ),
      ),
    );
  }

  // Widget _buildQuickStats(ReportProvider provider) {
  //   // Use server stats if available, otherwise use local stats
  //   final stats = _reportStats ?? provider.getLocalReportStats();

  //   // Handle both server and local stats formats
  //   Map<String, dynamic> displayStats = {};

  //   if (stats.containsKey('byStatus')) {
  //     // Server stats format
  //     final statusData = stats['byStatus'];
  //     displayStats = {
  //       'total': stats['total'] ?? 0,
  //       'pending': statusData?['pending'] ?? 0,
  //       'processing': statusData?['processing'] ?? 0,
  //       'resolved': statusData?['resolved'] ?? 0,
  //       'rejected': statusData?['rejected'] ?? 0,
  //     };
  //   } else {
  //     // Local stats format
  //     displayStats = {
  //       'total': stats['total'] ?? 0,
  //       'pending': stats['pending'] ?? 0,
  //       'processing': stats['processing'] ?? 0,
  //       'resolved': stats['resolved'] ?? 0,
  //       'rejected': stats['rejected'] ?? 0,
  //     };
  //   }

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [Colors.purple, Colors.purple.shade800],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.purple.withOpacity(0.3),
  //           blurRadius: 12,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildStatItem(
  //           'Total',
  //           displayStats['total'].toString(),
  //           Icons.assessment_rounded,
  //           'Semua laporan',
  //         ),
  //         _buildStatItem(
  //           'Pending',
  //           displayStats['pending'].toString(),
  //           Icons.pending_actions_rounded,
  //           'Laporan menunggu',
  //         ),
  //         _buildStatItem(
  //           'Diproses',
  //           displayStats['processing'].toString(),
  //           Icons.autorenew_rounded,
  //           'Sedang diproses',
  //         ),
  //         _buildStatItem(
  //           'Selesai',
  //           displayStats['resolved'].toString(),
  //           Icons.check_circle_rounded,
  //           'Laporan selesai',
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildStatItem(
  //   String label,
  //   String value,
  //   IconData icon,
  //   String tooltip,
  // ) {
  //   return Tooltip(
  //     message: tooltip,
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(10),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.2),
  //             shape: BoxShape.circle,
  //           ),
  //           child: Icon(icon, color: Colors.white, size: 22),
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           value,
  //           style: const TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         ),
  //         const SizedBox(height: 2),
  //         Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 11,
  //             color: Colors.white.withOpacity(0.9),
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFilterSection(ReportProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_alt_rounded,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Laporan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filter
          _buildFilterChips(
            'Status:',
            provider.statusFilters,
            provider.selectedFilter,
            (value) {
              provider.setFilter(value);
              if (value != 'Semua') {
                provider.loadReportsByStatus(value, refresh: true);
              } else {
                provider.loadReports(refresh: true);
              }
            },
            Colors.purple,
          ),
          const SizedBox(height: 12),

          // Category Filter
          _buildFilterChips(
            'Kategori:',
            provider.categoryFilters,
            provider.selectedCategory,
            (value) {
              provider.setCategory(value);
              if (value != 'Semua') {
                provider.loadReportsByCategory(value, refresh: true);
              } else {
                provider.loadReports(refresh: true);
              }
            },
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    String title,
    List<String> filters,
    String selectedFilter,
    Function(String) onSelected,
    Color selectedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => onSelected(filter),
              backgroundColor: Colors.grey[100],
              selectedColor: selectedColor.withOpacity(0.15),
              checkmarkColor: selectedColor,
              labelStyle: TextStyle(
                color: isSelected ? selectedColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? selectedColor : Colors.grey[300]!,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContent(ReportProvider provider, List<Report> reports) {
    if (provider.isLoading && provider.reports.isEmpty && !_isLoadingMore) {
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
      onRefresh: _refreshData,
      color: Colors.purple,
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: reports.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == reports.length) {
            return _buildLoadMoreIndicator();
          }
          final report = reports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReportCard(report, context),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.purple, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            'Memuat laporan...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReportProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 72, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Terjadi kesalahan yang tidak diketahui',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => provider.loadReports(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _initializeData(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Bantuan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return SingleChildScrollView(
      // Tambahkan SingleChildScrollView
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Penting!
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.assignment_outlined,
                  size: 60, // Ukuran lebih kecil
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isFiltered
                      ? 'Tidak Ada Hasil Ditemukan'
                      : 'Belum Ada Laporan',
                  style: TextStyle(
                    fontSize: 16, // Font lebih kecil
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? 'Coba ubah kata kunci pencarian atau filter yang digunakan'
                      : 'Laporan dari masyarakat akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14, // Font lebih kecil
                  ),
                  maxLines: 2,
                ),
                if (!isFiltered) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateReportDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_comment_rounded, size: 16 , color: Colors.white,),
                    label: const Text('Buat Laporan' ,style: TextStyle(color: Colors.white),),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(Report report, BuildContext context) {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    final canEdit = provider.canEditReport(report);
    final canDelete = provider.canDeleteReport(report);

    // Get status color and text
    final statusColor = _getStatusColor(report.status);
    final statusText = _getStatusText(report.status);
    final categoryIcon = _getCategoryIcon(report.category);
    final categoryText = report.category;
    final timeAgo = _getTimeAgo(report.createdAt);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showReportDetails(context, report),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan status dan category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(categoryIcon, size: 18, color: statusColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoryText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

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
                const SizedBox(height: 12),

                // Image preview jika ada
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: _getImageProvider(report.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Progress bar untuk status
                if (report.status != 'RESOLVED' && report.status != 'REJECTED')
                  _buildProgressBar(report.status),

                const SizedBox(height: 12),

                // Footer dengan waktu dan actions
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    if (report.userId != null) ...[
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'User #${report.userId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (canEdit || canDelete)
                      _buildActionMenu(report, context, canEdit, canDelete),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(
    Report report,
    BuildContext context,
    bool canEdit,
    bool canDelete,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
      onSelected: (value) => _handleAction(value, report, context),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (canEdit) {
          items.add(
            PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit Laporan'),
                ],
              ),
            ),
          );

          items.add(
            PopupMenuItem(
              value: 'status',
              child: const Row(
                children: [
                  Icon(Icons.update_rounded, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Ubah Status'),
                ],
              ),
            ),
          );
        }

        if (canDelete) {
          if (canEdit) {
            items.add(const PopupMenuDivider());
          }

          items.add(
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  const Text('Hapus Laporan'),
                ],
              ),
            ),
          );
        }

        return items;
      },
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

  Widget _buildProgressBar(String? status) {
    if (status == null) return const SizedBox();

    double progress = 0.0;
    String progressText = 'Menunggu';

    if (status == 'PENDING') {
      progress = 0.3;
      progressText = 'Dalam Antrian';
    } else if (status == 'PROCESSING') {
      progress = 0.7;
      progressText = 'Sedang Diproses';
    } else if (status == 'RESOLVED') {
      progress = 1.0;
      progressText = 'Selesai';
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: Colors.purple,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progressText,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
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
    File? imageFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_comment_rounded, color: Colors.purple),
                SizedBox(width: 12),
                Text(
                  'Buat Laporan Baru',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Laporan*',
                      hintText: 'Masukkan judul laporan yang jelas...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Lengkap*',
                      hintText: 'Jelaskan secara detail apa yang terjadi...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                      DropdownMenuItem(
                        value: 'Infrastruktur',
                        child: Text('Infrastruktur'),
                      ),
                      DropdownMenuItem(value: 'Sampah', child: Text('Sampah')),
                      DropdownMenuItem(
                        value: 'Keamanan',
                        child: Text('Keamanan'),
                      ),
                      DropdownMenuItem(
                        value: 'Kesehatan',
                        child: Text('Kesehatan'),
                      ),
                      DropdownMenuItem(
                        value: 'Lingkungan',
                        child: Text('Lingkungan'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  // Bagian upload gambar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.camera_alt_rounded,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tambahkan Foto Bukti',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unggah foto untuk memperkuat laporan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? pickedFile = await ImagePicker()
                                .pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1200,
                                  maxHeight: 1200,
                                  imageQuality: 80,
                                );

                            if (pickedFile != null) {
                              setState(() {
                                imageFile = File(pickedFile.path);
                              });
                              _showSuccessSnackbar('Gambar berhasil diunggah');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: const Text('Unggah Gambar'),
                        ),
                      ],
                    ),
                  ),
                  // Preview gambar yang dipilih
                  if (imageFile != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
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
                        imageFile: imageFile,
                      );
                      _showSuccessSnackbar(
                        'Laporan berhasil dibuat dan akan diproses!',
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      _showErrorSnackbar('Gagal membuat laporan: $e');
                    }
                  } else {
                    _showErrorSnackbar('Harap isi semua field yang diperlukan');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Kirim Laporan'),
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
    File? imageFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_rounded, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Edit Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Laporan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                      DropdownMenuItem(
                        value: 'Infrastruktur',
                        child: Text('Infrastruktur'),
                      ),
                      DropdownMenuItem(value: 'Sampah', child: Text('Sampah')),
                      DropdownMenuItem(
                        value: 'Keamanan',
                        child: Text('Keamanan'),
                      ),
                      DropdownMenuItem(
                        value: 'Kesehatan',
                        child: Text('Kesehatan'),
                      ),
                      DropdownMenuItem(
                        value: 'Lingkungan',
                        child: Text('Lingkungan'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  // Bagian edit gambar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Foto Bukti Saat Ini',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        if (report.imageUrl != null &&
                            report.imageUrl!.isNotEmpty)
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: _getImageProvider(report.imageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          const Column(
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tidak ada gambar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final XFile? pickedFile = await ImagePicker()
                                      .pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1200,
                                        maxHeight: 1200,
                                        imageQuality: 80,
                                      );
                                  if (pickedFile != null) {
                                    setState(() {
                                      imageFile = File(pickedFile.path);
                                    });
                                    _showSuccessSnackbar(
                                      'Gambar berhasil diubah',
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                ),
                                label: const Text('Ganti Foto'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (report.imageUrl != null &&
                                report.imageUrl!.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    // Set imageFile to null to indicate delete
                                    setState(() {
                                      imageFile = null;
                                    });
                                    _showSuccessSnackbar(
                                      'Gambar akan dihapus saat update',
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Hapus'),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
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
                        imageFile: imageFile,
                      );
                      _showSuccessSnackbar('Laporan berhasil diupdate');
                      Navigator.pop(context);
                    } catch (e) {
                      _showErrorSnackbar('Gagal mengupdate laporan: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Update Laporan'),
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
            title: const Row(
              children: [
                Icon(Icons.update_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Text(
                  'Ubah Status Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah status untuk laporan:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status options dengan feedback visual
                  Column(
                    children: [
                      _buildStatusOption(
                        'PENDING',
                        'Menunggu',
                        Icons.pending_actions_rounded,
                        Colors.orange,
                        selectedStatus,
                        setState,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusOption(
                        'PROCESSING',
                        'Diproses',
                        Icons.autorenew_rounded,
                        Colors.blue,
                        selectedStatus,
                        setState,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusOption(
                        'RESOLVED',
                        'Selesai',
                        Icons.check_circle_rounded,
                        Colors.green,
                        selectedStatus,
                        setState,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusOption(
                        'REJECTED',
                        'Ditolak',
                        Icons.cancel_rounded,
                        Colors.red,
                        selectedStatus,
                        setState,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Tutup dialog dulu
                  await _updateReportStatus(report, selectedStatus);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Simpan Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusOption(
    String value,
    String label,
    IconData icon,
    Color color,
    String selectedStatus,
    Function setState,
  ) {
    final isSelected = selectedStatus == value;

    return InkWell(
      onTap: () => setState(() => selectedStatus = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(Report report, String status) async {
    final provider = Provider.of<ReportProvider>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Mengupdate status...'),
          ],
        ),
      ),
    );

    try {
      final result = await provider.updateReportStatus(report.id, status);

      Navigator.pop(context); // Close loading dialog

      // Show success
      _showSuccessSnackbar(result['message'] ?? 'Status berhasil diubah');

      // Refresh data
      await provider.refreshData();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      // Show error with retry option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Gagal Mengupdate'),
            ],
          ),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showStatusDialog(context, report);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Hapus Laporan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus laporan ini?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              report.title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
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
                _showSuccessSnackbar('Laporan berhasil dihapus');
              } catch (e) {
                _showErrorSnackbar('Gagal menghapus laporan: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Hapus'),
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
          decoration: const BoxDecoration(
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status dan Category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                report.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(report.status),
                              ),
                            ),
                            child: Text(
                              _getStatusText(report.status).toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(report.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              (report.category).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Deskripsi:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Gambar yang dilaporkan
                      if (report.imageUrl != null &&
                          report.imageUrl!.isNotEmpty) ...[
                        const Text(
                          'Foto Bukti Laporan:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                _buildImageWidget(report.imageUrl!),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.grey[50],
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.photo_library_rounded,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Foto bukti yang dilaporkan oleh masyarakat',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.zoom_in_rounded,
                                          size: 20,
                                          color: Colors.purple,
                                        ),
                                        onPressed: () => _showImageFullScreen(
                                          context,
                                          report.imageUrl!,
                                          report.title,
                                        ),
                                        tooltip: 'Lihat gambar penuh',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        // Jika tidak ada gambar
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.photo_library_rounded,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tidak Ada Foto Bukti',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Laporan ini tidak dilampiri gambar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // User Info
                      if (report.userId != null) ...[
                        const Text(
                          'Informasi Pelapor:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'User ID: ${report.userId}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Laporan dibuat oleh masyarakat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Timestamps
                      const Text(
                        'Informasi Waktu:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
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
                                      fontSize: 14,
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
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  // Method untuk menampilkan gambar full screen
  void _showImageFullScreen(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black87,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child:
                      (imageUrl.startsWith('http') || imageUrl.startsWith('/'))
                      ? Image.network(
                          imageUrl.startsWith('/')
                              ? '${ReportProvider.imageBaseUrl}$imageUrl'
                              : imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFullScreenError();
                          },
                        )
                      : Image.file(
                          File(
                            imageUrl.startsWith('file://')
                                ? imageUrl.replaceFirst('file://', '')
                                : imageUrl,
                          ),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFullScreenError();
                          },
                        ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pinch untuk zoom • Geser untuk melihat detail',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 50, color: Colors.white),
        SizedBox(height: 16),
        Text('Gagal memuat gambar', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu';
      case 'PROCESSING':
        return 'Diproses';
      case 'RESOLVED':
        return 'Selesai';
      case 'REJECTED':
        return 'Ditolak';
      default:
        return 'Tidak diketahui';
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'infrastruktur':
        return Icons.construction_rounded;
      case 'sampah':
        return Icons.delete_rounded;
      case 'keamanan':
        return Icons.security_rounded;
      case 'kesehatan':
        return Icons.medical_services_rounded;
      case 'lingkungan':
        return Icons.eco_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
