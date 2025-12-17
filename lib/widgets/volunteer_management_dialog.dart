// widgets/volunteer_management_dialog.dart
import 'package:flutter/material.dart';
import '../models/emergency.dart';

class VolunteerManagementDialog extends StatelessWidget {
  final Emergency emergency;
  final Function(int) onNeedVolunteers;
  final VoidCallback onNoVolunteers;
  final VoidCallback onViewVolunteers;

  const VolunteerManagementDialog({
    super.key,
    required this.emergency,
    required this.onNeedVolunteers,
    required this.onNoVolunteers,
    required this.onViewVolunteers,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.people_rounded, color: Colors.blue),
          SizedBox(width: 12),
          Text('Kelola Relawan'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kelola kebutuhan relawan untuk:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            emergency.typeText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        if (emergency.volunteers.isNotEmpty)
          OutlinedButton(
            onPressed: onViewVolunteers,
            child: const Text('Lihat Relawan'),
          ),
        if (!emergency.needVolunteer)
          ElevatedButton(
            onPressed: () => _showNeedVolunteersDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Butuh Relawan'),
          ),
        if (emergency.needVolunteer)
          ElevatedButton(
            onPressed: onNoVolunteers,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Cukup Relawan'),
          ),
      ],
    );
  }

  void _showNeedVolunteersDialog(BuildContext context) {
    final countController = TextEditingController(
      text: emergency.volunteerCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Butuh Berapa Relawan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan jumlah relawan yang dibutuhkan:'),
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
            onPressed: () {
              final count = int.tryParse(countController.text) ?? 0;
              if (count > 0) {
                Navigator.pop(context); // Close count dialog
                Navigator.pop(context); // Close management dialog
                onNeedVolunteers(count);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );
  }
}
