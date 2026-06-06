import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/caretaker_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'doctor_home_screen.dart';
import 'doctor_register_screen.dart';
import 'admin_home_screen.dart';
import 'pending_approval_screen.dart';
import 'caretaker/caretaker_home_screen.dart';
import 'caretaker/caretaker_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  // 0 = patient, 1 = doctor, 2 = admin, 3 = caretaker
  int _selectedRole = 0;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    UserCredential? cred;

    try {
      cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Login failed. Please try again.';
        _loading = false;
      });
      return;
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
        _loading = false;
      });
      return;
    }

    if (!mounted) return;

    if (_selectedRole == 2) {
      // ── Admin login ────────────────────────────────────────────────
      bool isAdmin = false;
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        isAdmin = adminDoc.exists;
      } catch (e) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'Could not reach the server. Check your internet connection.';
          _loading = false;
        });
        return;
      }

      if (!isAdmin) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'No admin account found for this email.';
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.setUser(cred.user);
      try {
        await provider.loadAdminData();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else if (_selectedRole == 1) {
      // ── Doctor login ───────────────────────────────────────────────
      bool isDoctor = false;
      Map<String, dynamic>? doctorData;
      try {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        isDoctor = doctorDoc.exists;
        doctorData = doctorDoc.data();
      } catch (e) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'Could not reach the server. Check your internet connection.';
          _loading = false;
        });
        return;
      }

      if (!isDoctor) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'No doctor account found for this email. Please register as a doctor.';
          _loading = false;
        });
        return;
      }

      if (!mounted) return;

      // Check approval status
      final approvalStatus = doctorData?['approvalStatus'] ?? 'approved';
      if (approvalStatus == 'pending') {
        final provider = Provider.of<DoctorProvider>(context, listen: false);
        provider.setUser(cred.user);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const PendingApprovalScreen(isDoctor: true)),
        );
        return;
      }
      if (approvalStatus == 'rejected') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'Your doctor account has been rejected. Please contact support.';
          _loading = false;
        });
        return;
      }

      final provider = Provider.of<DoctorProvider>(context, listen: false);
      provider.setUser(cred.user);
      try {
        await provider.loadDoctorData();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
      );
    } else if (_selectedRole == 3) {
      // ── Caretaker login ────────────────────────────────────────────
      Map<String, dynamic>? caretakerData;
      try {
        final caretakerDoc = await FirebaseFirestore.instance
            .collection('caretakers')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        caretakerData = caretakerDoc.data();
        if (!caretakerDoc.exists) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() {
            _error = 'No caretaker account found. Please register first.';
            _loading = false;
          });
          return;
        }
      } catch (e) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'Could not reach the server. Check your internet connection.';
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      final provider = Provider.of<CaretakerProvider>(context, listen: false);
      provider.setUser(cred.user);
      try {
        await provider.loadCaretakerData();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CaretakerHomeScreen()),
      );
    } else {
      // ── Patient login ──────────────────────────────────────────────
      Map<String, dynamic>? userData;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        userData = userDoc.data();
      } catch (_) {}

      if (!mounted) return;

      final approvalStatus = userData?['approvalStatus'] ?? 'approved';
      if (approvalStatus == 'pending') {
        final provider = Provider.of<UserProvider>(context, listen: false);
        provider.setUser(cred.user);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const PendingApprovalScreen(isDoctor: false)),
        );
        return;
      }
      if (approvalStatus == 'rejected') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'Your account has been rejected. Please contact support.';
          _loading = false;
        });
        return;
      }

      final provider = Provider.of<UserProvider>(context, listen: false);
      provider.setUser(cred.user);
      try {
        await provider.loadUserData();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8785A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              const Text('Welcome back!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D3D3A))),
              const SizedBox(height: 6),
              const Text('Sign in to your account',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888780))),
              const SizedBox(height: 24),

              // ── Role Toggle ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _roleTab(0, 'Patient', Icons.pregnant_woman,
                        const Color(0xFFE8785A)),
                    _roleTab(1, 'Doctor', Icons.medical_services_rounded,
                        const Color(0xFF185FA5)),
                    _roleTab(2, 'Admin', Icons.admin_panel_settings_rounded,
                        const Color(0xFF6C3483)),
                    _roleTab(3, 'Caretaker', Icons.people_alt_rounded,
                        const Color(0xFF2E7D32)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildInput(_emailController, 'Email', Icons.email_outlined,
                  inputType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildInput(
                  _passwordController, 'Password', Icons.lock_outline,
                  obscure: true),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF7C1C1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFA32D2D), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFA32D2D), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole == 0
                        ? const Color(0xFFE8785A)
                        : _selectedRole == 1
                            ? const Color(0xFF185FA5)
                            : _selectedRole == 3
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF6C3483),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Sign In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              // Register link — only for patient, doctor and caretaker
              if (_selectedRole != 2) ...[
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => _selectedRole == 1
                            ? const DoctorRegisterScreen()
                            : _selectedRole == 3
                                ? const CaretakerRegisterScreen()
                                : const RegisterScreen(),
                      ));
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: const TextStyle(
                            color: Color(0xFF888780), fontSize: 15),
                        children: [
                          TextSpan(
                            text: _selectedRole == 1
                                ? 'Register as Doctor'
                                : _selectedRole == 3
                                    ? 'Register as Caretaker'
                                    : 'Create one',
                            style: TextStyle(
                              color: _selectedRole == 0
                                  ? const Color(0xFFE8785A)
                                  : _selectedRole == 1
                                      ? const Color(0xFF185FA5)
                                      : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(int index, String label, IconData icon, Color activeColor) {
    final selected = _selectedRole == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = index;
          _error = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? activeColor : const Color(0xFF888780)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? activeColor : const Color(0xFF888780),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType? inputType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: inputType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB4B2A9)),
          prefixIcon: Icon(icon, color: const Color(0xFFB4B2A9), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
