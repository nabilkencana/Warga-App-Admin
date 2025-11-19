// widgets/emergency_card.dart
import 'package:flutter/material.dart';
import '../models/emergency.dart';

class EmergencyCard extends StatelessWidget {
  final Emergency emergency;
  final VoidCallback onTap;
  final VoidCallback onVolunteer;
  final Function(Emergency) onManage;

  const EmergencyCard({
    super.key,
    required this.emergency,
    required this.onTap,
    required this.onVolunteer,
    required this.onManage,
  });

  // Tambahkan method canManage di sini
  bool get canManage {
    // Ganti dengan logika sesuai kebutuhan
    // Contoh: return emergency.createdBy == currentUserId;
    return true; // Untuk testing
  }

  bool get isVolunteer {
    // Ganti dengan logika sesuai kebutuhan
    return emergency.volunteers.any(
      (v) => v.userId == 1,
    ); // Ganti dengan ID user yang login
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: emergency.statusColor, width: 6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDetails(),
              const SizedBox(height: 12),
              _buildVolunteerSection(),
              const SizedBox(height: 12),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: emergency.statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            emergency.typeIcon,
            size: 20,
            color: emergency.statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emergency.typeText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                emergency.timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: emergency.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            emergency.statusText,
            style: TextStyle(
              fontSize: 11,
              color: emergency.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emergency.details != null && emergency.details!.isNotEmpty) ...[
          Text(
            emergency.details!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        if (emergency.location != null && emergency.location!.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  emergency.location!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVolunteerSection() {
    if (!emergency.needVolunteer || emergency.status != 'ACTIVE') {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.volunteer_activism_rounded, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dibutuhkan Relawan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  '${emergency.approvedVolunteersCount} dari ${emergency.volunteerCount} relawan terkumpul',
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ),
          ),
          if (!isVolunteer && emergency.canVolunteer)
            ElevatedButton(
              onPressed: onVolunteer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Daftar',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          if (isVolunteer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Terdaftar',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lihat Detail'),
              ),
              if (canManage && emergency.status == 'ACTIVE')
                OutlinedButton(
                  onPressed: () => onManage(emergency),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.orange),
                  ),
                  child: const Text(
                    'Kelola',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
