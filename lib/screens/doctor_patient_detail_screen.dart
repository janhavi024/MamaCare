import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: const Color(0xFF185FA5),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Appointments'),
            Tab(text: 'Medications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsTab(patientId: widget.patientId, doctorId: doctorId, patientName: widget.patientName),
          _AppointmentsTab(patientId: widget.patientId, doctorId: doctorId, patientName: widget.patientName),
          _MedicationsTab(patientId: widget.patientId, doctorId: doctorId, patientName: widget.patientName),
        ],
      ),
    );
  }
}

// ─── REPORTS TAB ─────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  final String patientId, doctorId, patientName;
  const _ReportsTab({required this.patientId, required this.doctorId, required this.patientName});

  void _showAddReport(BuildContext context) {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String reportType = 'Sonography';
    final types = ['Sonography', 'Blood Test', 'Urine Test', 'ECG', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: reportType,
                decoration: _inputDecoration('Report Type'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setModalState(() => reportType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: _inputDecoration('Report Title (e.g. Week 20 Anomaly Scan)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 4,
                decoration: _inputDecoration('Findings / Notes'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await FirebaseFirestore.instance.collection('reports').add({
                      'patientId': patientId,
                      'doctorId': doctorId,
                      'patientName': patientName,
                      'type': reportType,
                      'title': titleCtrl.text.trim(),
                      'notes': notesCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Post Report'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReport(context),
        backgroundColor: const Color(0xFF185FA5),
        label: const Text('Add Report', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
            //.orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF185FA5)));
          if (snap.hasError) return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: Color(0xFF888780))));
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 60, color: Color(0xFFB4B2A9)),
                  SizedBox(height: 12),
                  Text('No reports yet', style: TextStyle(color: Color(0xFF888780))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              final date = ts != null ? _formatDate(ts.toDate()) : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECE8E3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(data['type'] ?? '',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF185FA5),
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(date,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF888780))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(data['notes'],
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF888780))),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

// ─── APPOINTMENTS TAB ─────────────────────────────────────────────────────────

class _AppointmentsTab extends StatelessWidget {
  final String patientId, doctorId, patientName;
  const _AppointmentsTab({required this.patientId, required this.doctorId, required this.patientName});

  void _showSchedule(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule Appointment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Date Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: Color(0xFF185FA5)),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFECE8E3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFF185FA5), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: Color(0xFF185FA5)),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModalState(() => selectedTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFECE8E3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          color: Color(0xFF185FA5), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: notesCtrl,
                decoration: _inputDecoration('Notes (purpose of appointment)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final dt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    await FirebaseFirestore.instance.collection('appointments').add({
                      'patientId': patientId,
                      'doctorId': doctorId,
                      'patientName': patientName,
                      'dateTime': Timestamp.fromDate(dt),
                      'notes': notesCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Schedule'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSchedule(context),
        backgroundColor: const Color(0xFF185FA5),
        label: const Text('Schedule', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
            //.orderBy('dateTime')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF185FA5)));
          if (snap.hasError) return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: Color(0xFF888780))));
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Color(0xFFB4B2A9)),
                  SizedBox(height: 12),
                  Text('No appointments scheduled', style: TextStyle(color: Color(0xFF888780))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final dt = (data['dateTime'] as Timestamp).toDate();
              final isPast = dt.isBefore(DateTime.now());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isPast
                          ? const Color(0xFFECE8E3)
                          : const Color(0xFF185FA5),
                      width: isPast ? 1 : 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isPast
                            ? const Color(0xFFF0F0F0)
                            : const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${dt.day}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isPast
                                      ? const Color(0xFF888780)
                                      : const Color(0xFF185FA5))),
                          Text(_monthAbbr(dt.month),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isPast
                                      ? const Color(0xFF888780)
                                      : const Color(0xFF185FA5))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_timeStr(dt),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (data['notes'] != null &&
                              data['notes'].toString().isNotEmpty)
                            Text(data['notes'],
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF888780))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPast
                            ? const Color(0xFFF0F0F0)
                            : const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPast ? 'Past' : 'Upcoming',
                        style: TextStyle(
                            fontSize: 10,
                            color: isPast
                                ? const Color(0xFF888780)
                                : const Color(0xFF3B6D11),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  String _timeStr(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

// ─── MEDICATIONS TAB ─────────────────────────────────────────────────────────

class _MedicationsTab extends StatelessWidget {
  final String patientId, doctorId, patientName;
  const _MedicationsTab({required this.patientId, required this.doctorId, required this.patientName});

  void _showAddMed(BuildContext context) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    String frequency = 'Once daily';
    final frequencies = [
      'Once daily',
      'Twice daily',
      'Three times daily',
      'Every 8 hours',
      'Every 12 hours',
      'As needed',
      'Weekly',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Medication',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: _inputDecoration('Medication name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                decoration: _inputDecoration('Dosage (e.g. 500mg)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: _inputDecoration('Frequency'),
                items: frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setModalState(() => frequency = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsCtrl,
                maxLines: 2,
                decoration: _inputDecoration('Special instructions (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('doctor_medications')
                        .add({
                      'patientId': patientId,
                      'doctorId': doctorId,
                      'patientName': patientName,
                      'name': nameCtrl.text.trim(),
                      'dosage': dosageCtrl.text.trim(),
                      'frequency': frequency,
                      'instructions': instructionsCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Medication'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMed(context),
        backgroundColor: const Color(0xFF185FA5),
        label: const Text('Add Medication', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctor_medications')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
           // .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF185FA5)));
          if (snap.hasError) return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: Color(0xFF888780))));
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 60, color: Color(0xFFB4B2A9)),
                  SizedBox(height: 12),
                  Text('No medications added', style: TextStyle(color: Color(0xFF888780))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECE8E3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication_rounded,
                          color: Color(0xFF3B6D11), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (data['dosage'] != null &&
                              data['dosage'].toString().isNotEmpty)
                            Text(data['dosage'],
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF888780))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3EE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(data['frequency'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE8785A),
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (data['instructions'] != null &&
                              data['instructions'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(data['instructions'],
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888780),
                                    fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFA32D2D), size: 20),
                      onPressed: () => FirebaseFirestore.instance
                          .collection('doctor_medications')
                          .doc(docs[i].id)
                          .delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B2A9)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECE8E3)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
