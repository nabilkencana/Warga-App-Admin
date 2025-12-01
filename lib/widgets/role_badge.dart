// widgets/role_badge.dart
import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final double fontSize;

  const RoleBadge({Key? key, required this.role, this.fontSize = 10})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleConfig = _getRoleConfig(role);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: roleConfig.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: roleConfig.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleConfig.icon, size: fontSize, color: Colors.white),
          SizedBox(width: 4),
          Text(
            roleConfig.displayName.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  RoleConfig _getRoleConfig(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return RoleConfig(
          displayName: 'Super Admin',
          gradientColors: [Colors.purple, Colors.deepPurple],
          shadowColor: Colors.purple.withOpacity(0.3),
          icon: Icons.security_rounded,
        );
      case 'admin':
        return RoleConfig(
          displayName: 'Admin',
          gradientColors: [Colors.red, Colors.orange],
          shadowColor: Colors.red.withOpacity(0.3),
          icon: Icons.admin_panel_settings_rounded,
        );
      case 'volunteer':
        return RoleConfig(
          displayName: 'Relawan',
          gradientColors: [Colors.green, Colors.teal],
          shadowColor: Colors.green.withOpacity(0.3),
          icon: Icons.volunteer_activism_rounded,
        );
      default:
        return RoleConfig(
          displayName: 'Warga',
          gradientColors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          shadowColor: Color(0xFF1E88E5).withOpacity(0.3),
          icon: Icons.person_rounded,
        );
    }
  }
}

class RoleConfig {
  final String displayName;
  final List<Color> gradientColors;
  final Color shadowColor;
  final IconData icon;

  RoleConfig({
    required this.displayName,
    required this.gradientColors,
    required this.shadowColor,
    required this.icon,
  });
}
