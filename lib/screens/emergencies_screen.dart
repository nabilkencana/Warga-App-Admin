// screens/emergencies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../models/emergency.dart';

class EmergenciesScreen extends StatefulWidget {
  const EmergenciesScreen({super.key});

  @override
  _EmergenciesScreenState createState() => _EmergenciesScreenState();
}

class _EmergenciesScreenState extends State<EmergenciesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);
      provider.loadActiveEmergencies();
      provider.setCurrentUserId(1); // Ganti dengan ID user yang login
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Emergency> _searchEmergencies(List<Emergency> emergencies) {
    if (_searchQuery.isEmpty) return emergencies;
    
    return emergencies.where((emergency) {
      final typeMatch = emergency.type.toLowerCase().contains(_searchQuery.toLowerCase());
      final detailsMatch = emergency.details != null && 
          emergency.details!.toLowerCase().contains(_searchQuery.toLowerCase());
      final locationMatch = emergency.location != null && 
          emergency.location!.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return typeMatch || detailsMatch || locationMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Keadaan Darurat'),
        backgroundColor: Colors.red,
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
              final provider = Provider.of<EmergencyProvider>(context, listen: false);
              provider.loadActiveEmergencies();
            },
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

              // Filter Chips
              _buildFilterSection(provider),

              // Content
              Expanded(
                child: _buildContent(provider, searchedEmergencies),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showQuickSOSDialog(context),
            backgroundColor: Colors.red,
            heroTag: 'sos_button',
            child: Icon(Icons.emergency, color: Colors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _showCreateEmergencyDialog(context),
            backgroundColor: Colors.orange,
            heroTag: 'create_button',
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari keadaan darurat...',
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

  Widget _buildQuickStats(EmergencyProvider provider) {
    final stats = {
      'total': provider.emergencies.length,
      'active': provider.emergencies.where((e) => e.status == 'ACTIVE').length,
      'needVolunteers': provider.emergencies.where((e) => e.needVolunteer && e.status == 'ACTIVE').length,
    };

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total']!.toString(), Icons.emergency, Colors.orange),
          _buildStatItem('Aktif', stats['active']!.toString(), Icons.warning, Colors.red),
          _buildStatItem('Butuh Relawan', stats['needVolunteers']!.toString(), Icons.people, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(EmergencyProvider provider) {
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
                selectedColor: Colors.red.withOpacity(0.2),
                checkmarkColor: Colors.red,
                labelStyle: TextStyle(
                  color: provider.selectedFilter == filter ? Colors.red : Colors.grey[700],
                  fontWeight: provider.selectedFilter == filter ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          // Type Filter
          Wrap(
            spacing: 8,
            children: provider.typeFilters.map((type) {
              return FilterChip(
                label: Text(type),
                selected: provider.selectedType == type,
                onSelected: (selected) => provider.setType(type),
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
                labelStyle: TextStyle(
                  color: provider.selectedType == type ? Colors.orange : Colors.grey[700],
                  fontWeight: provider.selectedType == type ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EmergencyProvider provider, List<Emergency> emergencies) {
    if (provider.isLoading && provider.emergencies.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (emergencies.isEmpty) {
      return _buildEmptyState(_searchQuery.isNotEmpty || provider.selectedFilter != 'Semua' || provider.selectedType != 'Semua');
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadActiveEmergencies(),
      color: Colors.red,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: emergencies.length,
        itemBuilder: (context, index) {
          final emergency = emergencies[index];
          return _buildEmergencyCard(emergency, context);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Memuat keadaan darurat...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(EmergencyProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Gagal memuat keadaan darurat',
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
              onPressed: () => provider.loadActiveEmergencies(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
            isFiltered ? Icons.search_off : Icons.emergency_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak ada hasil' : 'Tidak ada keadaan darurat',
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
                : 'Semua keadaan darurat telah ditangani',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(Emergency emergency, BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    final canManage = provider.canManageEmergency(emergency);
    final isVolunteer = provider.isUserVolunteer(emergency);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: emergency.statusColor,
              width: 6,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan type dan status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: emergency.statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(emergency.typeIcon, size: 20, color: emergency.statusColor),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergency.typeText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          emergency.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: emergency.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: emergency.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      emergency.statusText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: emergency.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Details
              if (emergency.details != null && emergency.details!.isNotEmpty) ...[
                Text(
                  emergency.details!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
              ],

              // Location
              if (emergency.location != null && emergency.location!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        emergency.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],

              // Volunteer Info
              if (emergency.needVolunteer && emergency.status == 'ACTIVE') ...[
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dibutuhkan Relawan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              '${emergency.approvedVolunteersCount} dari ${emergency.volunteerCount} relawan terdaftar',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isVolunteer && emergency.canVolunteer)
                        ElevatedButton(
                          onPressed: () => _showVolunteerDialog(context, emergency),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size(0, 0),
                          ),
                          child: Text(
                            'Daftar',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      if (isVolunteer)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sudah Daftar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],

              // Footer dengan actions
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        // View Details Button
                        OutlinedButton(
                          onPressed: () => _showEmergencyDetails(context, emergency),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size(0, 0),
                            side: BorderSide(color: Colors.grey),
                          ),
                          child: Text(
                            'Detail',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),

                        // Manage buttons for authorized users
                        if (canManage && emergency.status == 'ACTIVE') ...[
                          OutlinedButton(
                            onPressed: () => _showManageDialog(context, emergency),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size(0, 0),
                              side: BorderSide(color: Colors.orange),
                            ),
                            child: Text(
                              'Kelola',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Quick action menu
                  if (canManage)
                    _buildActionMenu(emergency, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(Emergency emergency, BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 16, color: Colors.grey),
      onSelected: (value) => _handleAction(value, emergency, context),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (emergency.status == 'ACTIVE') {
          items.addAll([
            PopupMenuItem(
              value: 'resolve',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Tandai Selesai'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Batalkan'),
                ],
              ),
            ),
          ]);
        }

        if (emergency.status == 'ACTIVE' && !emergency.needVolunteer) {
          items.add(
            PopupMenuItem(
              value: 'need_volunteers',
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Butuh Relawan'),
                ],
              ),
            ),
          );
        }

        if (emergency.needVolunteer) {
          items.add(
            PopupMenuItem(
              value: 'no_volunteers',
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Tidak Butuh Relawan'),
                ],
              ),
            ),
          );
        }

        items.add(
          PopupMenuItem(
            value: 'volunteers',
            child: Row(
              children: [
                Icon(Icons.list, size: 16, color: Colors.purple),
                SizedBox(width: 8),
                Text('Lihat Relawan'),
              ],
            ),
          ),
        );

        return items;
      },
    );
  }

  void _handleAction(String action, Emergency emergency, BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    
    switch (action) {
      case 'resolve':
        _showResolveDialog(context, emergency);
        break;
      case 'cancel':
        _showCancelDialog(context, emergency);
        break;
      case 'need_volunteers':
        _showNeedVolunteersDialog(context, emergency);
        break;
      case 'no_volunteers':
        _showNoVolunteersDialog(context, emergency);
        break;
      case 'volunteers':
        _showVolunteersList(context, emergency);
        break;
    }
  }

  void _showQuickSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('SOS Darurat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih jenis keadaan darurat:'),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSOSButton('Kebakaran', Icons.local_fire_department, Colors.red, context),
                _buildQuickSOSButton('Kecelakaan', Icons.car_crash, Colors.orange, context),
                _buildQuickSOSButton('Medis', Icons.medical_services, Colors.green, context),
                _buildQuickSOSButton('Bencana', Icons.nature, Colors.brown, context),
              ],
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

  Widget _buildQuickSOSButton(String type, IconData icon, Color color, BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        _createQuickSOS(type, context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(type),
    );
  }

  void _createQuickSOS(String type, BuildContext context) async {
    try {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);
      await provider.createSOS(type: type);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS $type berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            title: Row(
              children: [
                Icon(Icons.add_alert, color: Colors.orange),
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
                    decoration: InputDecoration(
                      labelText: 'Jenis Darurat',
                      hintText: 'Contoh: Kebakaran, Banjir, Kecelakaan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    decoration: InputDecoration(
                      labelText: 'Detail Kejadian',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: needVolunteer,
                        onChanged: (value) => setState(() => needVolunteer = value!),
                      ),
                      Text('Butuh Relawan'),
                      if (needVolunteer) ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Jumlah Relawan',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              volunteerCount = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                      ],
                    ],
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
                  if (typeController.text.isNotEmpty) {
                    try {
                      final provider = Provider.of<EmergencyProvider>(context, listen: false);
                      await provider.createSOS(
                        type: typeController.text,
                        details: detailsController.text.isEmpty ? null : detailsController.text,
                        location: locationController.text.isEmpty ? null : locationController.text,
                        needVolunteer: needVolunteer,
                        volunteerCount: volunteerCount,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Keadaan darurat berhasil dibuat'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuat keadaan darurat: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Buat'),
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
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.blue),
            SizedBox(width: 8),
            Text('Daftar Sebagai Relawan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Daftar untuk membantu: ${emergency.typeText}'),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              controller: skillsController,
              decoration: InputDecoration(
                labelText: 'Keahlian/Keterampilan',
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
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                try {
                  final provider = Provider.of<EmergencyProvider>(context, listen: false);
                  await provider.registerVolunteer(
                    emergencyId: emergency.id,
                    userName: nameController.text,
                    userPhone: phoneController.text,
                    skills: skillsController.text.isEmpty ? null : skillsController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Berhasil mendaftar sebagai relawan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mendaftar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Daftar'),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status dan Type
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              emergency.typeText.toUpperCase(),
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Details
                      if (emergency.details != null && emergency.details!.isNotEmpty) ...[
                        Text(
                          'Detail:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          emergency.details!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Location
                      if (emergency.location != null && emergency.location!.isNotEmpty) ...[
                        Text(
                          'Lokasi:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              emergency.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],

                      // Volunteer Info
                      if (emergency.needVolunteer) ...[
                        Text(
                          'Informasi Relawan:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people, size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
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
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  SizedBox(width: 8),
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

  // ... (Other dialog methods for manage, resolve, cancel, etc.)

  void _showManageDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kelola Keadaan Darurat'),
        content: Text('Pilih aksi untuk ${emergency.typeText}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNeedVolunteersDialog(context, emergency);
            },
            child: Text('Butuh Relawan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showResolveDialog(context, emergency);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Tandai Selesai'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menandai ${emergency.typeText} sebagai selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = Provider.of<EmergencyProvider>(context, listen: false);
                await provider.updateStatus(emergency.id, 'RESOLVED');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Keadaan darurat berhasil diselesaikan'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menyelesaikan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Batalkan Keadaan Darurat'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin membatalkan ${emergency.typeText}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = Provider.of<EmergencyProvider>(context, listen: false);
                await provider.updateStatus(emergency.id, 'CANCELLED');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Keadaan darurat berhasil dibatalkan'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membatalkan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showNeedVolunteersDialog(BuildContext context, Emergency emergency) {
    final countController = TextEditingController(text: emergency.volunteerCount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.blue),
            SizedBox(width: 8),
            Text('Butuh Relawan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Berapa banyak relawan yang dibutuhkan?'),
            SizedBox(height: 16),
            TextField(
              controller: countController,
              decoration: InputDecoration(
                labelText: 'Jumlah Relawan',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              final count = int.tryParse(countController.text) ?? 0;
              if (count > 0) {
                try {
                  final provider = Provider.of<EmergencyProvider>(context, listen: false);
                  await provider.toggleNeedVolunteer(
                    id: emergency.id,
                    needVolunteer: true,
                    volunteerCount: count,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Permintaan relawan berhasil dikirim'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengirim permintaan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Kirim Permintaan'),
          ),
        ],
      ),
    );
  }

  void _showNoVolunteersDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text('Tidak Butuh Relawan'),
          ],
        ),
        content: Text('Apakah Anda yakin tidak membutuhkan relawan lagi untuk ${emergency.typeText}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = Provider.of<EmergencyProvider>(context, listen: false);
                await provider.toggleNeedVolunteer(
                  id: emergency.id,
                  needVolunteer: false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status relawan berhasil diupdate'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengupdate status: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: Text('Ya, Update'),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
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
                      'Daftar Relawan - ${emergency.typeText}',
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
                child: emergency.volunteers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada relawan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: emergency.volunteers.length,
                        itemBuilder: (context, index) {
                          final volunteer = emergency.volunteers[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: volunteer.statusColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: volunteer.statusColor,
                                ),
                              ),
                              title: Text(volunteer.userName ?? 'Anonim'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (volunteer.userPhone != null) Text(volunteer.userPhone!),
                                  if (volunteer.skills != null) Text(volunteer.skills!),
                                ],
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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