import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/caretaker_provider.dart';
import 'caretaker_home_screen.dart';

class CaretakerRegisterScreen extends StatefulWidget {
  const CaretakerRegisterScreen({super.key});

  @override
  State<CaretakerRegisterScreen> createState() =>
      _CaretakerRegisterScreenState();
}

class _CaretakerRegisterScreenState extends State<CaretakerRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _patientEmailController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final patientEmail = _patientEmailController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || patientEmail.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Find patient by email in users collection
      final patientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: patientEmail)
          .limit(1)
          .get();

      if (patientQuery.docs.isEmpty) {
        setState(() {
          _error = 'No patient found with that email. Ask the patient to register first.';
          _loading = false;
        });
        return;
      }

      final patientDoc = patientQuery.docs.first;
      final linkedPatientId = patientDoc.id;
      final patientName = patientDoc.data()['name'] ?? '';

      // Create Firebase Auth account
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save caretaker doc
      await FirebaseFirestore.instance
          .collection('caretakers')
          .doc(cred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'linkedPatientId': linkedPatientId,
        'linkedPatientName': patientName,
        'linkedPatientEmail': patientEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'caretaker',
      });

      if (!mounted) return;

      final provider = Provider.of<CaretakerProvider>(context, listen: false);
      provider.setUser(cred.user);
      await provider.loadCaretakerData();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CaretakerHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Registration failed.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: const Text('Register as Caretaker'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Create Caretaker Account',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D3D3A))),
              const SizedBox(height: 6),
              const Text('You will be linked to your patient',
                  style: TextStyle(color: Color(0xFF888780))),
              const SizedBox(height: 24),

              _buildInput(_nameController, 'Your full name', Icons.person_outline),
              const SizedBox(height: 14),
              _buildInput(_emailController, 'Your email',
                  Icons.email_outlined,
                  inputType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildInput(_passwordController, 'Password (min 6 chars)',
                  Icons.lock_outline,
                  obscure: true),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.link_rounded,
                            color: Color(0xFF2E7D32), size: 18),
                        SizedBox(width: 8),
                        Text('Link to Patient',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter the email of the patient you are caring for.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
                    ),
                    const SizedBox(height: 12),
                    _buildInput(_patientEmailController, "Patient's email",
                        Icons.email_outlined,
                        inputType: TextInputType.emailAddress),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(10),
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
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
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
                      : const Text('Register',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _patientEmailController.dispose();
    super.dispose();
  }
}
