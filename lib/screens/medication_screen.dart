import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  String _frequency = 'Once daily';
  final _frequencies = ['Once daily', 'Twice daily', 'Three times daily', 'As needed'];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _medsRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('medications');

  Future<void> _addMedication() async {
    if (_nameController.text.isEmpty || _doseController.text.isEmpty) return;
    await _medsRef.add({
      'name': _nameController.text.trim(),
      'dose': _doseController.text.trim(),
      'frequency': _frequency,
      'taken': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
    _nameController.clear();
    _doseController.clear();
    Navigator.pop(context);
  }

  Future<void> _toggleTaken(String id, bool current) async {
    await _medsRef.doc(id).update({'taken': !current});
  }

  Future<void> _deleteMed(String id) async {
    await _medsRef.doc(id).delete();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Medication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D3D3A))),
            const SizedBox(height: 16),
            _inputField(_nameController, 'Medication name'),
            const SizedBox(height: 12),
            _inputField(_doseController, 'Dosage (e.g. 500mg)'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECE8E3)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8785A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Medication', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFECE8E3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddDialog,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _medsRef.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE8785A)));
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error loading medications: ${snap.error}',
                  style: const TextStyle(color: Color(0xFF888780))),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No medications yet', style: TextStyle(color: Color(0xFF888780))),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showAddDialog,
                    child: const Text('Add your first medication', style: TextStyle(color: Color(0xFFE8785A))),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final taken = data['taken'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECE8E3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: GestureDetector(
                    onTap: () => _toggleTaken(doc.id, taken),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: taken ? const Color(0xFFEAF3DE) : const Color(0xFFFEF3EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        taken ? Icons.check_circle : Icons.circle_outlined,
                        color: taken ? const Color(0xFF3B6D11) : const Color(0xFFE8785A),
                      ),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D3D3A),
                      decoration: taken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    '${data['dose']} • ${data['frequency']}',
                    style: const TextStyle(color: Color(0xFF888780), fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFB4B2A9)),
                    onPressed: () => _deleteMed(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFE8785A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }
}
