import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/doctor_provider.dart';
import 'doctor_home_screen.dart';
import 'pending_approval_screen.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedSpecialization = 'Obstetrics & Gynaecology';
  bool _loading = false;
  String? _error;

  final List<String> _specializations = [
    'Obstetrics & Gynaecology',
    'Maternal-Fetal Medicine',
    'Reproductive Endocrinology',
    'Neonatology',
    'General Gynaecology',
    'Perinatology',
    'Gynaecologic Oncology',
  ];

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _qualificationController.text.trim().isEmpty ||
        _experienceController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(cred.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'yearsOfExperience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'specialization': _selectedSpecialization,
        'bio': _bioController.text.trim(),
        'profileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
        'approvalStatus': 'pending',
        'role': 'doctor',
        'documents': [],
      });

      if (!mounted) return;
      final provider = Provider.of<DoctorProvider>(context, listen: false);
      provider.setUser(cred.user);
      await provider.loadDoctorData();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen(isDoctor: true)),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        backgroundColor: const Color(0xFF185FA5),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Doctor Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3D3D3A))),
              const SizedBox(height: 4),
              const Text('Fill in your professional details',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888780))),
              const SizedBox(height: 24),

              _sectionLabel('Personal Information'),
              const SizedBox(height: 10),
              _buildInput(_nameController, 'Full name *', Icons.person_outline),
              const SizedBox(height: 12),
              _buildInput(_emailController, 'Email *', Icons.email_outlined),
              const SizedBox(height: 12),
              _buildInput(_passwordController, 'Password (min 6 chars) *', Icons.lock_outline, obscure: true),
              const SizedBox(height: 12),
              _buildInput(_phoneController, 'Phone number', Icons.phone_outlined),

              const SizedBox(height: 20),
              _sectionLabel('Professional Details'),
              const SizedBox(height: 10),
              _buildInput(_qualificationController, 'Qualifications (e.g. MBBS, MD) *', Icons.school_outlined),
              const SizedBox(height: 12),
              _buildInput(_experienceController, 'Years of experience *', Icons.work_outline,
                  inputType: TextInputType.number),
              const SizedBox(height: 12),
              _buildInput(_hospitalController, 'Hospital / Clinic name', Icons.local_hospital_outlined),
              const SizedBox(height: 12),

              // Specialization Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECE8E3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSpecialization,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFB4B2A9)),
                    items: _specializations.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedSpecialization = v!),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECE8E3)),
                ),
                child: TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Brief professional bio (optional)',
                    hintStyle: TextStyle(color: Color(0xFFB4B2A9)),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.info_outline, color: Color(0xFFB4B2A9), size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Doctor Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Color(0xFF185FA5), letterSpacing: 0.5));
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
