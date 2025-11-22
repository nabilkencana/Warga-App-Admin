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
  String _selectedStatus = 'Semua';
  String _selectedType = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmergencies();
    });
  }

  Future<void> _loadEmergencies() async {
    try {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);
      await provider.loadActiveEmergencies();
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Emergency> _filterEmergencies(List<Emergency> emergencies) {
    List<Emergency> filtered = emergencies;

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((emergency) {
        return emergency.type.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (emergency.details?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (emergency.location?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Filter berdasarkan status
    if (_selectedStatus != 'Semua') {
      filtered = filtered
          .where((emergency) => emergency.status == _selectedStatus)
          .toList();
    }

    // Filter berdasarkan jenis
    if (_selectedType != 'Semua') {
      filtered = filtered
          .where((emergency) => emergency.type == _selectedType)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Keadaan Darurat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmergencies,
          ),
        ],
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, child) {
          final filteredEmergencies = _filterEmergencies(provider.emergencies);

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(),

              // Simple Filter Section
              _buildSimpleFilterSection(provider),

              // Content
              Expanded(child: _buildContent(provider, filteredEmergencies)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEmergencyDialog(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari darurat...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
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
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildSimpleFilterSection(EmergencyProvider provider) {
    final statusList = ['Semua', 'ACTIVE', 'RESOLVED'];
    final typeList = [
      'Semua',
      ...provider.typeFilters.where((type) => type != 'Semua'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter
          _buildFilterRow('Status:', statusList, _selectedStatus, (value) {
            setState(() => _selectedStatus = value);
          }),
          const SizedBox(height: 12),

          // Type Filter
          _buildFilterRow('Jenis:', typeList, _selectedType, (value) {
            setState(() => _selectedType = value);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) => onChanged(option),
                  selectedColor: Colors.red.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.red : Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEmergencies,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text('Memuat keadaan darurat...'),
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
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmergencies,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Keadaan Darurat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saat ini tidak ada keadaan darurat yang aktif',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateEmergencyDialog(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Buat Laporan Darurat'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== DIALOG METHODS ==========

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
            title: const Text('Buat Keadaan Darurat'),
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
                      hintText: 'Jelaskan apa yang terjadi...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi',
                      hintText: 'Lokasi kejadian',
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
                        labelText: 'Jumlah Relawan',
                        border: OutlineInputBorder(),
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
                  if (typeController.text.isEmpty) {
                    _showErrorSnackbar('Jenis darurat harus diisi');
                    return;
                  }

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
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        title: const Text('Daftar Sebagai Relawan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bantu: ${emergency.type}'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap*',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon*',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: skillsController,
              decoration: const InputDecoration(
                labelText: 'Keahlian',
                hintText: 'Contoh: P3K, Evakuasi, Medis',
                border: OutlineInputBorder(),
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
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                _showErrorSnackbar('Nama dan nomor telepon harus diisi');
                return;
              }

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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDetails(BuildContext context, Emergency emergency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Detail Darurat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Jenis: ${emergency.type}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (emergency.details != null)
                Text('Detail: ${emergency.details}'),
              if (emergency.location != null)
                Text('Lokasi: ${emergency.location}'),
              const SizedBox(height: 8),
              Text('Status: ${emergency.status}'),
              if (emergency.needVolunteer)
                Text('Butuh Relawan: ${emergency.volunteerCount} orang'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
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
        title: const Text('Kelola Darurat'),
        content: Text('Aksi untuk "${emergency.type}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          if (emergency.status == 'ACTIVE')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResolveDialog(context, emergency);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Selesaikan'),
            ),
          if (emergency.needVolunteer)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showNoVolunteersDialog(context, emergency);
              },
              child: const Text('Cukup Relawan'),
            ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Darurat'),
        content: Text('Tandai "${emergency.type}" sebagai selesai?'),
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
                _showSuccessSnackbar('Darurat berhasil diselesaikan');
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

  void _showNoVolunteersDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cukup Relawan'),
        content: const Text('Tandai sudah cukup relawan?'),
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
                _showSuccessSnackbar('Status relawan diupdate');
                Navigator.pop(context);
              } catch (e) {
                _showErrorSnackbar('Gagal mengupdate: $e');
              }
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}
