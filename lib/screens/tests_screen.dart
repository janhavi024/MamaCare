import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _testsRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('tests');

  final _testNameController = TextEditingController();
  DateTime? _selectedDate;

  final _suggestedTests = [
    'Blood test (CBC)',
    'Urine test',
    'Glucose tolerance test',
    'Ultrasound / Anatomy scan',
    'Blood pressure check',
    'Thyroid test',
    'Iron / Hemoglobin test',
    'Anomaly scan',
  ];

  Future<void> _addTest(String name, DateTime date) async {
    await _testsRef.add({
      'name': name,
      'date': Timestamp.fromDate(date),
      'done': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleDone(String id, bool current) async {
    await _testsRef.doc(id).update({'done': !current});
  }

  Future<void> _deleteTest(String id) async {
    await _testsRef.doc(id).delete();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 280)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE8785A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule a Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D3D3A))),
              const SizedBox(height: 16),
              TextField(
                controller: _testNameController,
                decoration: InputDecoration(
                  hintText: 'Test name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Or pick a common test:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888780))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestedTests.map((t) => GestureDetector(
                  onTap: () => _testNameController.text = t,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3EE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0DDD5)),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF993C1D))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  await _pickDate();
                  setModalState(() {});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFECE8E3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFFB4B2A9)),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDate == null
                            ? 'Pick a date'
                            : DateFormat('EEE, d MMM yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null ? const Color(0xFFB4B2A9) : const Color(0xFF3D3D3A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_testNameController.text.isEmpty || _selectedDate == null) return;
                    await _addTest(_testNameController.text.trim(), _selectedDate!);
                    _testNameController.clear();
                    setState(() => _selectedDate = null);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8785A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Schedule Test', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(title: const Text('Tests & Checkups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _testsRef.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE8785A)));
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error loading tests: ${snap.error}',
                  style: const TextStyle(color: Color(0xFF888780))),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No tests scheduled', style: TextStyle(color: Color(0xFF888780))),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showAddDialog,
                    child: const Text('Schedule your first test', style: TextStyle(color: Color(0xFFE8785A))),
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
              final date = (data['date'] as Timestamp).toDate();
              final done = data['done'] == true;
              final isPast = date.isBefore(DateTime.now());
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: done ? const Color(0xFFC0DD97) : const Color(0xFFECE8E3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: GestureDetector(
                    onTap: () => _toggleDone(doc.id, done),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: done ? const Color(0xFFEAF3DE) : isPast ? const Color(0xFFFCEBEB) : const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        done ? Icons.check_circle : isPast ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
                        color: done ? const Color(0xFF3B6D11) : isPast ? const Color(0xFFA32D2D) : const Color(0xFF185FA5),
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D3D3A),
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('EEEE, d MMMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast && !done ? const Color(0xFFA32D2D) : const Color(0xFF888780),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFB4B2A9)),
                    onPressed: () => _deleteTest(doc.id),
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
    _testNameController.dispose();
    super.dispose();
  }
}
