import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{
    for (final k in ['name', 'email', 'phone', 'password', 'confirm', 'specialization', 'qualification', 'hospital', 'license', 'years', 'relationship'])
      k: TextEditingController()
  };
  String _role = 'PATIENT';
  DateTime? _due;
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v, [String label = 'This field']) => (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    String? nz(String k) => _c[k]!.text.trim().isEmpty ? null : _c[k]!.text.trim();
    final body = <String, dynamic>{
      'fullName': _c['name']!.text.trim(),
      'email': _c['email']!.text.trim(),
      'password': _c['password']!.text,
      'role': _role,
      'phone': nz('phone'),
      if (_role == 'PATIENT' && _due != null) 'dueDate': isoDate(_due!),
      if (_role == 'DOCTOR') ...{
        'specialization': nz('specialization'),
        'qualification': nz('qualification'),
        'hospital': nz('hospital'),
        'licenseNumber': nz('license'),
        'yearsOfExperience': int.tryParse(_c['years']!.text.trim()),
      },
      if (_role == 'CARETAKER') 'relationship': nz('relationship'),
    };
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = {};
    });
    try {
      await context.read<AuthProvider>().register(body);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _fieldErrors = e.fieldErrors;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String key, String label, {bool required = false, TextInputType? type, bool obscure = false, String? Function(String?)? validator, String? serverKey, IconData? icon}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon), errorText: _fieldErrors[serverKey ?? key]),
          validator: validator ?? (required ? (v) => _req(v, label) : null),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('I am a…', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'PATIENT', label: Text('Mother'), icon: Icon(Icons.pregnant_woman)),
                    ButtonSegment(value: 'DOCTOR', label: Text('Doctor'), icon: Icon(Icons.medical_services_outlined)),
                    ButtonSegment(value: 'CARETAKER', label: Text('Caretaker'), icon: Icon(Icons.family_restroom)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: 20),
                if (_role == 'DOCTOR') const Disclaimer('Doctor accounts are reviewed by an administrator before you can see patients.'),
                if (_error != null && _fieldErrors.isEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                _field('name', 'Full name', required: true, serverKey: 'fullName', icon: Icons.person_outline),
                _field('email', 'Email', type: TextInputType.emailAddress, icon: Icons.mail_outline,
                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email'),
                _field('phone', 'Phone (optional)', type: TextInputType.phone, icon: Icons.phone_outlined),
                _field('password', 'Password', obscure: true, icon: Icons.lock_outline,
                    validator: (v) => (v != null && v.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v))
                        ? null
                        : 'At least 8 characters with a letter and a number'),
                _field('confirm', 'Confirm password', obscure: true, icon: Icons.lock_outline,
                    validator: (v) => v == _c['password']!.text ? null : 'Passwords do not match'),
                if (_role == 'PATIENT')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      icon: const Icon(Icons.event),
                      label: Text(_due == null ? 'Estimated due date (optional)' : 'Due date: ${fmtDate(_due!)}'),
                      onPressed: () async {
                        final d = await pickDate(context, initial: _due ?? DateTime.now().add(const Duration(days: 140)), first: DateTime.now(), last: DateTime.now().add(const Duration(days: 280)));
                        if (d != null) setState(() => _due = d);
                      },
                    ),
                  ),
                if (_role == 'DOCTOR') ...[
                  _field('specialization', 'Specialization', required: true, icon: Icons.local_hospital_outlined),
                  _field('qualification', 'Qualification', required: true),
                  _field('hospital', 'Hospital / clinic'),
                  _field('license', 'Medical license number', required: true, serverKey: 'licenseNumber'),
                  _field('years', 'Years of experience', type: TextInputType.number, serverKey: 'yearsOfExperience'),
                ],
                if (_role == 'CARETAKER') _field('relationship', 'Relationship to the mother (e.g. Husband)'),
                const SizedBox(height: 8),
                BusyButton(label: 'Create account', busy: _busy, onPressed: _submit),
              ]),
            ),
          ),
        ),
      );
}
