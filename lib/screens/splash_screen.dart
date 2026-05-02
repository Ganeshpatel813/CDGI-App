import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'admin/admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    await auth.loadFromStorage();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => auth.isAdmin ? const AdminScreen() : const DashboardScreen(),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('CDGI Attendance',
              style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text('Chameli Devi Group of Institutions',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 40),
            const SizedBox(width: 32, height: 32,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
