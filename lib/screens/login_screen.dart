// lib/screens/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wargaapp_admin/providers/auth_provider.dart';
import 'package:wargaapp_admin/screens/admin_dashboard.dart';
import 'package:wargaapp_admin/screens/security_dashboard.dart';
import 'package:wargaapp_admin/screens/verify_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  int _countdown = 60;
  Timer? _timer;
  bool _showGoogleLogin = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
    _loadPendingEmail();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkExistingLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        _navigateBasedOnRole(authProvider.userRole!);
      }
    });
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadPendingEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pendingEmail = await authProvider.getPendingEmail();
    if (pendingEmail != null) {
      _emailController.text = pendingEmail;
      setState(() {
        authProvider.isOtpSent;
      });
    }
  }

  Future<void> _requestOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email harus valid')));
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.requestOtp(_emailController.text);

      // Navigate to verify OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyOtpScreen(email: _emailController.text),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP harus 6 digit')));
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.verifyOtp(
        _emailController.text,
        _otpController.text,
      );

      if (result['success']) {
        _navigateBasedOnRole(result['role']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final result = await authProvider.googleMobileLogin({
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'picture': googleUser.photoUrl,
        });

        if (result['success']) {
          _navigateBasedOnRole(result['role']);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google login gagal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateBasedOnRole(String role) {
    switch (role) {
      case 'ADMIN':
      case 'SUPER_ADMIN':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(
              token: Provider.of<AuthProvider>(context, listen: false).token!,
            ),
          ),
        );
        break;
      case 'SATPAM':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SecurityDashboardScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role tidak dikenali: $role'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/Logobiru.png', height: 100, width: 100),
                SizedBox(height: 24),

                // Title
                Text(
                  'WARGA KITA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                Text(
                  'Admin & Security Dashboard',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),

                // Email Input
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authProvider.isOtpSent,
                ),
                SizedBox(height: 16),

                // OTP Input (muncul setelah OTP dikirim)
                if (authProvider.isOtpSent) ...[
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Kode OTP (6 digit)',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: _countdown > 0
                          ? Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('$_countdown s'),
                            )
                          : TextButton(
                              onPressed: _requestOtp,
                              child: Text('Kirim Ulang'),
                            ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Masukkan 6 digit kode OTP yang dikirim ke email Anda',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                ],

                // Buttons
                if (authProvider.isLoading)
                  CircularProgressIndicator()
                else if (!authProvider.isOtpSent) ...[
                  ElevatedButton(
                    onPressed: _requestOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.blue[900],
                    ),
                    child: Text(
                      'Minta Kode OTP',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Divider untuk Google Login
                  if (_showGoogleLogin) ...[
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('atau'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Google Login Button
                    OutlinedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      icon: Image.asset(
                        'assets/googlelogo.png',
                        height: 24,
                        width: 24,
                      ),
                      label: Text(
                        'Masuk dengan Google',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ] else
                  ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Verifikasi OTP',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                SizedBox(height: 20),

                // Info Box
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[800],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Informasi Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• Hanya untuk Admin, Super Admin, dan Satpam\n'
                        '• OTP akan dikirim ke email terdaftar\n'
                        '• OTP berlaku 5 menit\n'
                        '• Dashboard berbeda untuk setiap role\n'
                        '• Untuk Satpam: gunakan email yang terdaftar di sistem security',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Message
                if (authProvider.error != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
