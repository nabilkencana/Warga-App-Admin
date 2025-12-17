// widgets/error_boundary.dart
import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ErrorWidgetBuilder(
      builder: (error, stackTrace) {
        // Log error ke console
        print('Error Boundary Caught: $error');
        print('Stack Trace: $stackTrace');

        // Tampilkan error screen yang user-friendly
        return Scaffold(
          backgroundColor: Color(0xFFF7F9FC),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Maaf, terjadi kesalahan dalam aplikasi. Silakan coba lagi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to dashboard
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Kembali ke Dashboard',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// Untuk Flutter versi lama, gunakan ini sebagai alternatif
class ErrorWidgetBuilder extends StatelessWidget {
  final Widget Function(Object error, StackTrace stackTrace) builder;
  final Widget child;

  const ErrorWidgetBuilder({
    super.key,
    required this.builder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
