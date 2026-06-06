import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/caretaker_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'doctor_home_screen.dart';
import 'admin_home_screen.dart';
import 'pending_approval_screen.dart';
import 'caretaker/caretaker_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _goTo(const LoginScreen());
        return;
      }

      // 1. Check admin
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 6));

        if (adminDoc.exists) {
          if (!mounted) return;
          final provider = Provider.of<AdminProvider>(context, listen: false);
          provider.setUser(user);
          try {
            await provider.loadAdminData();
          } catch (_) {}
          _goTo(const AdminHomeScreen());
          return;
        }
      } catch (_) {
        _goTo(const LoginScreen());
        return;
      }

      // 2. Check caretaker
      try {
        final caretakerDoc = await FirebaseFirestore.instance
            .collection('caretakers')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 6));

        if (caretakerDoc.exists) {
          if (!mounted) return;
          final provider =
              Provider.of<CaretakerProvider>(context, listen: false);
          provider.setUser(user);
          try {
            await provider.loadCaretakerData();
          } catch (_) {}
          _goTo(const CaretakerHomeScreen());
          return;
        }
      } catch (_) {}

      // 4. Check doctor
      bool isDoctor = false;
      Map<String, dynamic>? doctorData;
      try {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 6));
        isDoctor = doctorDoc.exists;
        doctorData = doctorDoc.data();
      } catch (_) {
        _goTo(const LoginScreen());
        return;
      }

      if (!mounted) return;

      if (isDoctor) {
        final approvalStatus = doctorData?['approvalStatus'] ?? 'approved';
        if (approvalStatus == 'pending') {
          _goTo(const PendingApprovalScreen(isDoctor: true));
          return;
        }
        if (approvalStatus == 'rejected') {
          await FirebaseAuth.instance.signOut();
          _goTo(const LoginScreen());
          return;
        }
        final provider = Provider.of<DoctorProvider>(context, listen: false);
        provider.setUser(user);
        try {
          await provider.loadDoctorData();
        } catch (_) {}
        _goTo(const DoctorHomeScreen());
      } else {
        // 3. Patient
        Map<String, dynamic>? userData;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 6));
          userData = userDoc.data();
        } catch (_) {}

        if (!mounted) return;

        final approvalStatus = userData?['approvalStatus'] ?? 'approved';
        if (approvalStatus == 'pending') {
          _goTo(const PendingApprovalScreen(isDoctor: false));
          return;
        }
        if (approvalStatus == 'rejected') {
          await FirebaseAuth.instance.signOut();
          _goTo(const LoginScreen());
          return;
        }

        final provider = Provider.of<UserProvider>(context, listen: false);
        provider.setUser(user);
        try {
          await provider.loadUserData();
        } catch (_) {}
        _goTo(const HomeScreen());
      }
    } catch (e) {
      if (mounted) _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8785A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'MamaCare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your pregnancy companion',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
