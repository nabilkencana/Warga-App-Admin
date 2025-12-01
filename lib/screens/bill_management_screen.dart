// screens/bill_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';

class BillManagementScreen extends StatefulWidget {
  final String token;

  const BillManagementScreen({super.key, required this.token});

  @override
  _BillManagementScreenState createState() => _BillManagementScreenState();
}

class _BillManagementScreenState extends State<BillManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterOptions = [
    'Semua',
    'Lunas',
    'Belum Bayar',
    'Nunggak',
  ];

  // ✅ TAMBAHKAN VARIABEL INI:
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;

  String _formatNumber(dynamic number) {
    // Convert to double jika perlu
    double value;
    if (number is int) {
      value = number.toDouble();
    } else if (number is double) {
      value = number;
    } else if (number is String) {
      value = double.tryParse(number) ?? 0.0;
    } else {
      value = 0.0;
    }

    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      billProvider.loadBills();
      billProvider.loadBillSummary();
      _loadUsers(); // Load users for bulk creation
    });
  }

  // ✅ METHOD UNTUK LOAD USERS
  Future<void> _loadUsers() async {
    print('🔄 Loading users...');
    setState(() => _isLoadingUsers = true);

    try {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      final users = await billProvider.getUsers();

      print('📊 Loaded ${users.length} users');

      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('❌ Error loading users: $e');
      setState(() {
        _allUsers = [];
        _isLoadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Financial Overview
            _buildFinancialOverview(),

            // Quick Actions
            _buildQuickActions(),

            // Filter & Search
            _buildFilterSection(),

            // Bills List
            Expanded(child: _buildBillsList()),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // --------------------- HEADER ---------------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEW: Back button row
          Row(
            children: [
              // Back Button
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 8),
              Icon(Icons.receipt_long, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "Manajemen Tagihan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshData,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Pantau status pembayaran warga",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --------------------- FINANCIAL OVERVIEW ---------------------
  Widget _buildFinancialOverview() {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final summary = billProvider.summary;
        final collectionRate = summary.collectionRate;

        return Container(
          margin: EdgeInsets.all(16),
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
          child: Column(
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Terkumpul",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: collectionRate / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            collectionRate >= 80
                                ? Color(0xFF4CAF50)
                                : collectionRate >= 50
                                ? Color(0xFFFF9800)
                                : Color(0xFFF44336),
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "${collectionRate.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rp ${summary.paidAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      Text(
                        "dari Rp ${summary.totalAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    "Total Tagihan",
                    "${summary.totalBills}",
                    Color(0xFF1E88E5),
                    Icons.receipt,
                  ),
                  _buildStatItem(
                    "Lunas",
                    "${summary.paidBills}",
                    Color(0xFF4CAF50),
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    "Nunggak",
                    "${summary.overdueBills}",
                    Color(0xFFF44336),
                    Icons.warning,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
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
              title,
              style: TextStyle(fontSize: 10, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------- QUICK ACTIONS ---------------------
  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // CHANGED: Now this creates bulk bills
          Expanded(
            child: _quickActionButton(
              icon: Icons.add,
              label: "Tagihan Massal",
              color: Color(0xFF1E88E5),
              onTap: () => _showCreateBulkBillDialog(context),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _quickActionButton(
              icon: Icons.send,
              label: "Kirim Reminder",
              color: Color(0xFFFF9800),
              onTap: _sendReminders,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _quickActionButton(
              icon: Icons.download,
              label: "Export",
              color: Color(0xFF4CAF50),
              onTap: _exportReport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------- NEW: BULK BILL CREATION DIALOG ---------------------
  // screens/bill_management_screen.dart - UPDATED MODERN POPUP

  void _showCreateBulkBillDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    DateTime dueDate = DateTime.now().add(Duration(days: 30));
    String _selectedCategory = 'iuran';
    bool _isRecurring = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalAmount = amountController.text.isNotEmpty
              ? (double.tryParse(amountController.text) ?? 0) * _allUsers.length
              : 0;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          radius: 24,
                          child: Icon(
                            Icons.group_add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Tagihan Massal",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _allUsers.isEmpty
                              ? "Memuat data warga..."
                              : "Untuk ${_allUsers.length} warga",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // QUICK INFO CARD
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF1E88E5),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Tagihan Akan Dikirim Ke",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        "${_allUsers.length} Warga",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E88E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // FORM FIELDS
                          _buildModernFormField(
                            label: "Judul Tagihan",
                            hintText: "Iuran Bulanan Maret 2024",
                            controller: titleController,
                            icon: Icons.title,
                            isRequired: true,
                          ),
                          SizedBox(height: 16),

                          _buildModernFormField(
                            label: "Deskripsi (Opsional)",
                            hintText: "Deskripsi singkat tagihan...",
                            controller: descController,
                            icon: Icons.description,
                            maxLines: 2,
                          ),
                          SizedBox(height: 16),

                          // CATEGORY CHIPS
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kategori",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildCategoryChip(
                                    'iuran',
                                    'Iuran',
                                    Icons.home,
                                    _selectedCategory,
                                    setDialogState,
                                  ),
                                  _buildCategoryChip(
                                    'sampah',
                                    'Sampah',
                                    Icons.delete,
                                    _selectedCategory,
                                    setDialogState,
                                  ),
                                  _buildCategoryChip(
                                    'keamanan',
                                    'Keamanan',
                                    Icons.security,
                                    _selectedCategory,
                                    setDialogState,
                                  ),
                                  _buildCategoryChip(
                                    'acara',
                                    'Acara',
                                    Icons.celebration,
                                    _selectedCategory,
                                    setDialogState,
                                  ),
                                  _buildCategoryChip(
                                    'perbaikan',
                                    'Perbaikan',
                                    Icons.build,
                                    _selectedCategory,
                                    setDialogState,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // AMOUNT INPUT
                          _buildModernFormField(
                            label: "Jumlah per Warga",
                            hintText: "100000",
                            controller: amountController,
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            prefixText: "Rp ",
                            onChanged: (value) {
                              setDialogState(() {});
                            },
                          ),
                          SizedBox(height: 16),

                          // DUE DATE
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_today,
                                color: Color(0xFF1E88E5),
                              ),
                              title: Text(
                                "Jatuh Tempo",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(dueDate),
                                style: TextStyle(fontSize: 13),
                              ),
                              trailing: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade500,
                              ),
                              onTap: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    Duration(days: 365),
                                  ),
                                );
                                if (selectedDate != null) {
                                  setDialogState(() => dueDate = selectedDate);
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 16),

                          // RECURRING OPTION
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.repeat,
                                color: Color(0xFF1E88E5),
                              ),
                              title: Text(
                                "Tagihan Berulang",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                "Buat tagihan secara otomatis setiap bulan",
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: Switch(
                                value: _isRecurring,
                                onChanged: (value) {
                                  setDialogState(() => _isRecurring = value);
                                },
                                activeColor: Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // SUMMARY CARD
                          if (amountController.text.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE3F2FD),
                                    Color(0xFFBBDEFB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF1E88E5).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics,
                                        color: Color(0xFF1E88E5),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Ringkasan Tagihan",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E88E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  _buildSummaryRow(
                                    "Per Warga:",
                                    "Rp ${_formatNumber(double.parse(amountController.text))}",
                                  ),
                                  _buildSummaryRow(
                                    "Jumlah Warga:",
                                    "${_allUsers.length} orang",
                                  ),
                                  Divider(
                                    height: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                  _buildSummaryRow(
                                    "Total Penerimaan:",
                                    "Rp ${_formatNumber(totalAmount)}",
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // FOOTER BUTTONS
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _allUsers.isEmpty
                                ? null
                                : () => _validateAndCreateBulkBill(
                                    context,
                                    titleController.text,
                                    descController.text,
                                    amountController.text,
                                    dueDate,
                                    _selectedCategory,
                                    _isRecurring,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Buat Tagihan",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🎨 MODERN FORM FIELD COMPONENT
  Widget _buildModernFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired) Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(icon, color: Color(0xFF1E88E5)),
              prefixText: prefixText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // 🎨 CATEGORY CHIP COMPONENT
  Widget _buildCategoryChip(
    String value,
    String label,
    IconData icon,
    String selectedValue,
    Function setDialogState,
  ) {
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: () {
        setDialogState(() {});
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF1E88E5) : Colors.grey.shade300,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF1E88E5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Color(0xFF1E88E5),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 SUMMARY ROW COMPONENT
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              color: isTotal ? Color(0xFF1E88E5) : Colors.grey.shade700,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              color: isTotal ? Color(0xFF1E88E5) : Colors.grey.shade700,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SIMPLIFIED VALIDATION METHOD
  void _validateAndCreateBulkBill(
    BuildContext context,
    String title,
    String description,
    String amount,
    DateTime dueDate,
    String category,
    bool isRecurring,
  ) async {
    // Validasi sederhana
    if (title.isEmpty || amount.isEmpty) {
      _showErrorDialog(
        context,
        "Data belum lengkap",
        "Harap isi judul dan jumlah tagihan",
      );
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      _showErrorDialog(
        context,
        "Jumlah tidak valid",
        "Harap masukkan angka yang valid",
      );
      return;
    }

    // Show beautiful loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
              ),
              SizedBox(height: 16),
              Text(
                "Membuat Tagihan...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Sedang membuat tagihan untuk ${_allUsers.length} warga",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );

    final billProvider = Provider.of<BillProvider>(context, listen: false);

    final success = await billProvider.createBulkBills(
      title: title,
      description: description,
      amount: amountValue,
      dueDate: dueDate,
      users: _allUsers,
    );

    Navigator.pop(context); // Close loading dialog

    if (success) {
      Navigator.pop(context); // Close main dialog
      _showSuccessDialog(
        context,
        "Tagihan berhasil dibuat untuk ${_allUsers.length} warga!",
      );
    } else {
      _showErrorDialog(
        context,
        "Terjadi Kesalahan",
        "Beberapa tagihan gagal dibuat",
      );
    }
  }

  // 🎨 SUCCESS DIALOG
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text(
                "Berhasil!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Mengerti"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 ERROR DIALOG
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------- FILTER & SEARCH ---------------------
  Widget _buildFilterSection() {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => billProvider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: "Cari nama warga...",
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Filter Tabs
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterOptions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _filterTab(
                        _filterOptions[index],
                        index,
                        billProvider,
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

  Widget _filterTab(String text, int index, BillProvider billProvider) {
    bool selected = billProvider.statusFilter == index;
    Color getColor(int index) {
      switch (index) {
        case 1:
          return Color(0xFF4CAF50); // Lunas - Hijau
        case 2:
          return Color(0xFFFFC107); // Belum Bayar - Kuning
        case 3:
          return Color(0xFFF44336); // Nunggak - Merah
        default:
          return Color(0xFF1E88E5); // Semua - Biru
      }
    }

    return GestureDetector(
      onTap: () => billProvider.setStatusFilter(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? getColor(index) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? getColor(index) : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: getColor(index).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) Icon(Icons.check, size: 14, color: Colors.white),
            if (selected) SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------- BILLS LIST ---------------------
  Widget _buildBillsList() {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        if (billProvider.isLoading && billProvider.bills.isEmpty) {
          return _buildLoadingState();
        }

        if (billProvider.error != null) {
          return _buildErrorState(billProvider.error!);
        }

        final filteredBills = billProvider.filteredBills;

        if (filteredBills.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredBills.length,
            itemBuilder: (context, index) {
              final bill = filteredBills[index];
              return _userBillCard(bill, billProvider);
            },
          ),
        );
      },
    );
  }

  Widget _userBillCard(UserBill bill, BillProvider billProvider) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info & Status
            Row(
              children: [
                // User Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.person, color: Color(0xFF1E88E5), size: 20),
                ),
                SizedBox(width: 12),

                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.user['namaLengkap']?.toString() ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        bill.user['email']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bill.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bill.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bill.statusIcon, size: 12, color: bill.statusColor),
                      SizedBox(width: 4),
                      Text(
                        bill.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: bill.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Bill Details
            Row(
              children: [
                _billDetailItem(
                  Icons.attach_money,
                  "Rp ${bill.amount.toStringAsFixed(0)}",
                ),
                SizedBox(width: 16),
                _billDetailItem(
                  Icons.calendar_today,
                  _formatDate(bill.dueDate),
                ),
                if (bill.daysOverdue > 0) ...[
                  SizedBox(width: 16),
                  _billDetailItem(
                    Icons.schedule,
                    "Terlambat ${bill.daysOverdue}h",
                    color: Colors.red,
                  ),
                ],
              ],
            ),

            SizedBox(height: 12),

            // Description
            if (bill.description.isNotEmpty) ...[
              Text(
                bill.description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              SizedBox(height: 12),
            ],

            // Action Buttons
            _buildActionButtons(bill, billProvider),
          ],
        ),
      ),
    );
  }

  Widget _billDetailItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserBill bill, BillProvider billProvider) {
    return Row(
      children: [
        if (!bill.isPaid) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showMarkAsPaidDialog(bill, billProvider),
              icon: Icon(Icons.check, size: 16),
              label: Text("Tandai Lunas"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showBillDetails(bill),
            icon: Icon(Icons.visibility, size: 16),
            label: Text("Detail"),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------- LOADING & ERROR STATES ---------------------
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E88E5)),
          SizedBox(height: 16),
          Text(
            "Memuat data tagihan...",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Terjadi Kesalahan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshData, child: Text("Coba Lagi")),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            "Tidak ada tagihan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Belum ada data tagihan untuk ditampilkan",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showCreateBillDialog(context),
            child: Text("Buat Tagihan Pertama"),
          ),
        ],
      ),
    );
  }

  // --------------------- FLOATING ACTION BUTTON ---------------------
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () =>
          _showCreateBulkBillDialog(context), // CHANGED to bulk creation
      backgroundColor: Color(0xFF1E88E5),
      foregroundColor: Colors.white,
      child: Icon(Icons.group_add), // CHANGED icon
      tooltip: "Buat Tagihan Massal",
    );
  }

  // --------------------- UTILITY METHODS ---------------------
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _refreshData() async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    await billProvider.loadBills();
    await billProvider.loadBillSummary();
  }

  void _sendReminders() {
    // TODO: Implement reminder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Fitur pengiriman reminder akan segera hadir!")),
    );
  }

  void _exportReport() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Fitur export laporan akan segera hadir!")),
    );
  }

  void _showBillDetails(UserBill bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detail Tagihan"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailItem(
                "Nama Warga",
                bill.user['namaLengkap']?.toString() ?? 'Unknown',
              ),
              _detailItem("Email", bill.user['email']?.toString() ?? '-'),
              _detailItem("Judul Tagihan", bill.title),
              _detailItem(
                "Deskripsi",
                bill.description.isEmpty ? '-' : bill.description,
              ),
              _detailItem("Jumlah", "Rp ${bill.amount.toStringAsFixed(0)}"),
              _detailItem("Jatuh Tempo", _formatDate(bill.dueDate)),
              _detailItem("Status", bill.statusText),
              if (bill.paidAt != null)
                _detailItem("Tanggal Bayar", _formatDate(bill.paidAt!)),
              if (bill.daysOverdue > 0)
                _detailItem("Keterlambatan", "${bill.daysOverdue} hari"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // --------------------- DIALOGS ---------------------
  void _showCreateBillDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController userIdController = TextEditingController();
    DateTime dueDate = DateTime.now().add(Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Buat Tagihan Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Judul Tagihan*",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "Deskripsi",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Jumlah (Rp)*",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: "ID User*",
                  border: OutlineInputBorder(),
                  hintText: "Masukkan ID user",
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text("Jatuh Tempo"),
                subtitle: Text(_formatDate(dueDate)),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    setState(() => dueDate = selectedDate);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  amountController.text.isEmpty ||
                  userIdController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Harap isi semua field yang wajib!")),
                );
                return;
              }

              final billProvider = Provider.of<BillProvider>(
                context,
                listen: false,
              );
              final success = await billProvider.createBill(
                title: titleController.text,
                description: descController.text,
                amount: double.parse(amountController.text),
                dueDate: dueDate,
                userId: int.parse(userIdController.text),
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Tagihan berhasil dibuat!")),
                );
              }
            },
            child: Text("Buat Tagihan"),
          ),
        ],
      ),
    );
  }

  void _showMarkAsPaidDialog(UserBill bill, BillProvider billProvider) {
    String selectedMethod = 'CASH';
    final List<String> paymentMethods = [
      'CASH',
      'QRIS',
      'MOBILE_BANKING',
      'BANK_TRANSFER',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Pembayaran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Konfirmasi bahwa:"),
            SizedBox(height: 8),
            Text(
              bill.user['namaLengkap']?.toString() ?? 'Unknown User',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "telah membayar tagihan:",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 4),
            Text(
              bill.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            Text(
              "Rp ${bill.amount.toStringAsFixed(0)}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              items: paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(_formatPaymentMethod(method)),
                );
              }).toList(),
              onChanged: (value) => selectedMethod = value!,
              decoration: InputDecoration(
                labelText: "Metode Pembayaran",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await billProvider.markAsPaid(
                bill.id,
                selectedMethod,
              );
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Tagihan berhasil ditandai sebagai lunas!"),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF50)),
            child: Text("Konfirmasi Lunas" , style: TextStyle(color:  Colors.white),),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'CASH':
        return 'Tunai';
      case 'QRIS':
        return 'QRIS';
      case 'MOBILE_BANKING':
        return 'Mobile Banking';
      case 'BANK_TRANSFER':
        return 'Transfer Bank';
      default:
        return method;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
