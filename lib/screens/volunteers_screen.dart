// screens/volunteers_screen.dart
import 'package:flutter/material.dart';

class VolunteersScreen extends StatelessWidget {
  const VolunteersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Volunteers'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildVolunteerCard(
            'Ahmad Santoso',
            'ahmad@example.com',
            'Medis',
            'Aktif',
          ),
          SizedBox(height: 12),
          _buildVolunteerCard(
            'Siti Rahayu',
            'siti@example.com',
            'Logistik',
            'Aktif',
          ),
          SizedBox(height: 12),
          _buildVolunteerCard(
            'Budi Prasetyo',
            'budi@example.com',
            'Evakuasi',
            'Non-Aktif',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new volunteer
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVolunteerCard(
    String name,
    String email,
    String skill,
    String status,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'V',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text('Keahlian: $skill', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'Aktif' ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
