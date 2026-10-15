import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    // Restore the session, but keep the branding visible for a moment.
    Future.wait([auth.restore(), Future.delayed(const Duration(milliseconds: 1200))]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9D5FF), AppColors.background]),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.lavender, AppColors.lavenderDark]),
                boxShadow: [BoxShadow(color: AppColors.lavenderDark.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))],
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('MamaCare', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Your pregnancy companion', style: TextStyle(color: AppColors.muted, fontSize: 16)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(strokeWidth: 3),
          ]),
        ),
      );
}
