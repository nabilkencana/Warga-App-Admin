// screens/emergencies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../models/emergency.dart';
import '../widgets/emergency_card.dart';

class EmergenciesScreen extends StatefulWidget {
  const EmergenciesScreen({super.key});

  @override
  _EmergenciesScreenState createState() => _EmergenciesScreenState();
}

class _EmergenciesScreenState extends State<EmergenciesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);
      await provider.loadActiveEmergencies();
      provider.setCurrentUserId(1); // Ganti dengan ID user yang login
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data awal: $e');
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
    super.dispose();
  }

  List<Emergency> _searchEmergencies(List<Emergency> emergencies) {
    if (_searchQuery.isEmpty) return emergencies;

    return emergencies.where((emergency) {
      final typeMatch = emergency.type.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final detailsMatch =
          emergency.details != null &&
          emergency.details!.toLowerCase().contains(_searchQuery.toLowerCase());
      final locationMatch =
          emergency.location != null &&
          emergency.location!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return typeMatch || detailsMatch || locationMatch;
    }).toList();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);
      await provider.loadActiveEmergencies();
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
          'Keadaan Darurat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.red,
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
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, child) {
          final searchedEmergencies = _searchEmergencies(provider.emergencies);

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(),

              // Quick Stats
              if (!provider.isLoading && provider.emergencies.isNotEmpty)
                _buildQuickStats(provider),

              // Filter Section
              _buildFilterSection(provider),

              // Content
              Expanded(child: _buildContent(provider, searchedEmergencies)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
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
            hintText: 'Cari jenis, lokasi, atau detail darurat...',
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
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
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildQuickStats(EmergencyProvider provider) {
    final stats = {
      'total': provider.emergencies.length,
      'active': provider.emergencies.where((e) => e.status == 'ACTIVE').length,
      'needVolunteers': provider.emergencies
          .where((e) => e.needVolunteer && e.status == 'ACTIVE')
          .length,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Darurat',
            stats['total']!.toString(),
            Icons.emergency_rounded,
            Colors.orange,
            'Semua keadaan darurat',
          ),
          _buildStatItem(
            'Aktif',
            stats['active']!.toString(),
            Icons.warning_amber_rounded,
            Colors.red,
            'Darurat yang sedang berlangsung',
          ),
          _buildStatItem(
            'Butuh Relawan',
            stats['needVolunteers']!.toString(),
            Icons.volunteer_activism_rounded,
            Colors.blue,
            'Memerlukan bantuan relawan',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(EmergencyProvider provider) {
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
                'Filter Data',
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
            provider.setFilter,
            Colors.red,
          ),
          const SizedBox(height: 12),

          // Type Filter
          _buildFilterChips(
            'Jenis:',
            provider.typeFilters,
            provider.selectedType,
            provider.setType,
            Colors.orange,
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

  Widget _buildContent(
    EmergencyProvider provider,
    List<Emergency> emergencies,
  ) {
    if (provider.isLoading && provider.emergencies.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (emergencies.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty ||
            provider.selectedFilter != 'Semua' ||
            provider.selectedType != 'Semua',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.red,
      backgroundColor: Colors.white,
      displacement: 20,
      edgeOffset: 20,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: emergencies.length,
        itemBuilder: (context, index) {
          final emergency = emergencies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EmergencyCard(
              emergency: emergency,
              onTap: () => _showEmergencyDetails(context, emergency),
              onVolunteer: () => _showVolunteerDialog(context, emergency),
              onManage: (emergency) => _showManageDialog(context, emergency),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.red, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            'Memuat keadaan darurat...',
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

  Widget _buildErrorState(EmergencyProvider provider) {
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
                  onPressed: () => provider.loadActiveEmergencies(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.emergency_share_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'Tidak Ada Hasil Ditemukan'
                  : 'Belum Ada Keadaan Darurat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFiltered
                  ? 'Coba ubah kata kunci pencarian atau filter yang digunakan'
                  : 'Saat ini tidak ada keadaan darurat yang aktif. Semua dalam kondisi aman.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateEmergencyDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_alert_rounded),
                label: const Text('Buat Laporan Darurat'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick SOS Button
        FloatingActionButton(
          onPressed: () => _showQuickSOSDialog(context),
          backgroundColor: Colors.red,
          heroTag: 'sos_button',
          tooltip: 'SOS Darurat Cepat',
          child: const Icon(
            Icons.emergency_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        // Create Emergency Button
        FloatingActionButton(
          onPressed: () => _showCreateEmergencyDialog(context),
          backgroundColor: Colors.orange,
          heroTag: 'create_button',
          tooltip: 'Buat Laporan Darurat',
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  // ========== DIALOG METHODS ==========

  void _showQuickSOSDialog(BuildContext context) {
    final List<Map<String, dynamic>> quickTypes = [
      {
        'type': 'Kebakaran',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.red,
        'description': 'Laporkan kebakaran bangunan, hutan, atau kendaraan',
      },
      {
        'type': 'Kecelakaan',
        'icon': Icons.car_crash_rounded,
        'color': Colors.orange,
        'description': 'Kecelakaan lalu lintas atau kerja',
      },
      {
        'type': 'Medis',
        'icon': Icons.medical_services_rounded,
        'color': Colors.green,
        'description': 'Darurat kesehatan dan medis',
      },
      {
        'type': 'Bencana',
        'icon': Icons.nature_people_rounded,
        'color': Colors.brown,
        'description': 'Banjir, gempa, longsor, dll',
      },
    ];

    // Show bottom sheet with quick SOS options
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pilih Jenis Darurat',
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quickTypes.length,
                itemBuilder: (context, index) {
                  final item = quickTypes[index];
                  final color = item['color'] as Color;
                  final type = item['type'] as String;
                  final description = item['description'] as String;
                  final icon = item['icon'] as IconData;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(type),
                      subtitle: Text(description),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        _createQuickSOS(type, context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createQuickSOS(String type, BuildContext context) async {
    try {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);
      await provider.createSOS(type: type);

      _showSuccessSnackbar(
        'SOS $type berhasil dikirim! Tim respon telah diberitahu.',
      );
    } catch (e) {
      _showErrorSnackbar('Gagal mengirim SOS: $e');
    }
  }

  void _showCreateEmergencyDialog(BuildContext context) {
    final typeController = TextEditingController();
    final detailsController = TextEditingController();
    final locationController = TextEditingController();
    bool needVolunteer = false;
    int volunteerCount = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_alert_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Buat Keadaan Darurat'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Darurat*',
                      hintText: 'Contoh: Kebakaran, Banjir, Kecelakaan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Detail Kejadian',
                      hintText: 'Jelaskan secara singkat apa yang terjadi...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi',
                      hintText: 'Lokasi kejadian (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: needVolunteer,
                        onChanged: (value) =>
                            setState(() => needVolunteer = value!),
                      ),
                      const Text('Butuh Relawan'),
                    ],
                  ),
                  if (needVolunteer) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Relawan yang Dibutuhkan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        volunteerCount = int.tryParse(value) ?? 0;
                      },
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
                  if (typeController.text.isNotEmpty) {
                    try {
                      final provider = Provider.of<EmergencyProvider>(
                        context,
                        listen: false,
                      );
                      await provider.createSOS(
                        type: typeController.text,
                        details: detailsController.text.isEmpty
                            ? null
                            : detailsController.text,
                        location: locationController.text.isEmpty
                            ? null
                            : locationController.text,
                        needVolunteer: needVolunteer,
                        volunteerCount: volunteerCount,
                      );
                      _showSuccessSnackbar('Laporan darurat berhasil dibuat!');
                      Navigator.pop(context);
                    } catch (e) {
                      _showErrorSnackbar('Gagal membuat laporan: $e');
                    }
                  } else {
                    _showErrorSnackbar('Jenis darurat harus diisi');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Buat Laporan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVolunteerDialog(BuildContext context, Emergency emergency) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final skillsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Daftar Sebagai Relawan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daftar untuk membantu: ${emergency.typeText}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: skillsController,
              decoration: const InputDecoration(
                labelText: 'Keahlian/Keterampilan',
                hintText: 'Contoh: P3K, Evakuasi, Medis, dll.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_rounded),
              ),
              maxLines: 2,
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
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                try {
                  final provider = Provider.of<EmergencyProvider>(
                    context,
                    listen: false,
                  );
                  await provider.registerVolunteer(
                    emergencyId: emergency.id,
                    userName: nameController.text,
                    userPhone: phoneController.text,
                    skills: skillsController.text.isEmpty
                        ? null
                        : skillsController.text,
                  );
                  _showSuccessSnackbar('Berhasil mendaftar sebagai relawan!');
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackbar('Gagal mendaftar: $e');
                }
              } else {
                _showErrorSnackbar('Nama dan nomor telepon harus diisi');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Daftar Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDetails(BuildContext context, Emergency emergency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
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
                      'Detail Darurat',
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
                      // Status dan Type
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: emergency.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: emergency.statusColor),
                            ),
                            child: Text(
                              emergency.statusText.toUpperCase(),
                              style: TextStyle(
                                color: emergency.statusColor,
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
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              emergency.typeText.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Details
                      if (emergency.details != null &&
                          emergency.details!.isNotEmpty) ...[
                        const Text(
                          'Detail:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emergency.details!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Location
                      if (emergency.location != null &&
                          emergency.location!.isNotEmpty) ...[
                        const Text(
                          'Lokasi:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                emergency.location!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Volunteer Info
                      if (emergency.needVolunteer) ...[
                        const Text(
                          'Informasi Relawan:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people_rounded,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dibutuhkan: ${emergency.volunteerCount} relawan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Terkumpul: ${emergency.approvedVolunteersCount} relawan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                  '${emergency.createdAt.day}/${emergency.createdAt.month}/${emergency.createdAt.year} ${emergency.createdAt.hour}:${emergency.createdAt.minute.toString().padLeft(2, '0')}',
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
                                  '${emergency.updatedAt.day}/${emergency.updatedAt.month}/${emergency.updatedAt.year} ${emergency.updatedAt.hour}:${emergency.updatedAt.minute.toString().padLeft(2, '0')}',
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

  void _showManageDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Kelola Keadaan Darurat'),
          ],
        ),
        content: Text('Pilih aksi untuk "${emergency.typeText}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          if (emergency.needVolunteer)
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _showNoVolunteersDialog(context, emergency);
              },
              child: const Text('Cukup Relawan'),
            ),
          if (!emergency.needVolunteer)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showNeedVolunteersDialog(context, emergency);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Butuh Relawan'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showResolveDialog(context, emergency);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Tandai Selesai'),
          ),
        ],
      ),
    );
  }

  void _showNeedVolunteersDialog(BuildContext context, Emergency emergency) {
    final countController = TextEditingController(
      text: emergency.volunteerCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Butuh Relawan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berapa banyak relawan yang dibutuhkan?'),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Relawan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_rounded),
              ),
              keyboardType: TextInputType.number,
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
              final count = int.tryParse(countController.text) ?? 0;
              if (count > 0) {
                try {
                  final provider = Provider.of<EmergencyProvider>(
                    context,
                    listen: false,
                  );
                  await provider.toggleNeedVolunteer(
                    id: emergency.id,
                    needVolunteer: true,
                    volunteerCount: count,
                  );
                  _showSuccessSnackbar('Permintaan relawan berhasil dikirim');
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackbar('Gagal mengirim permintaan: $e');
                }
              } else {
                _showErrorSnackbar('Jumlah relawan harus lebih dari 0');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );
  }

  void _showNoVolunteersDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people_outline_rounded, color: Colors.grey),
            SizedBox(width: 8),
            Text('Tidak Butuh Relawan'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin tidak membutuhkan relawan lagi untuk "${emergency.typeText}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = Provider.of<EmergencyProvider>(
                  context,
                  listen: false,
                );
                await provider.toggleNeedVolunteer(
                  id: emergency.id,
                  needVolunteer: false,
                );
                _showSuccessSnackbar('Status relawan berhasil diupdate');
                Navigator.pop(context);
              } catch (e) {
                _showErrorSnackbar('Gagal mengupdate status: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Ya, Update'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Tandai Selesai'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menandai "${emergency.typeText}" sebagai selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = Provider.of<EmergencyProvider>(
                  context,
                  listen: false,
                );
                await provider.updateStatus(emergency.id, 'RESOLVED');
                _showSuccessSnackbar('Keadaan darurat berhasil diselesaikan');
                Navigator.pop(context);
              } catch (e) {
                _showErrorSnackbar('Gagal menyelesaikan: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );
  }

  void _showVolunteersList(BuildContext context, Emergency emergency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
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
                    Text(
                      'Daftar Relawan - ${emergency.typeText}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: emergency.volunteers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada relawan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: emergency.volunteers.length,
                        itemBuilder: (context, index) {
                          final volunteer = emergency.volunteers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: volunteer.statusColor
                                    .withOpacity(0.1),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: volunteer.statusColor,
                                ),
                              ),
                              title: Text(volunteer.userName ?? 'Anonim'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (volunteer.userPhone != null)
                                    Text(volunteer.userPhone!),
                                  if (volunteer.skills != null)
                                    Text(
                                      volunteer.skills!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: volunteer.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  volunteer.statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: volunteer.statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
