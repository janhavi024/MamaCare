import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDueDateScreen extends StatefulWidget {
  const DoctorDueDateScreen({super.key});

  @override
  State<DoctorDueDateScreen> createState() => _DoctorDueDateScreenState();
}

class _DoctorDueDateScreenState extends State<DoctorDueDateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Pregnancy Due Dates'),
        backgroundColor: const Color(0xFF185FA5),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Patients'),
            Tab(text: 'Saved Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PatientDueDateTab(),
          _SavedRecordsTab(),
        ],
      ),
    );
  }
}

// ─── PATIENT DUE DATE TAB ─────────────────────────────────────────────────────
// Shows all accepted patients with their pregnancy due date fetched from
// the 'users' Firestore collection (stored at registration).

class _PatientDueDateTab extends StatefulWidget {
  const _PatientDueDateTab();

  @override
  State<_PatientDueDateTab> createState() => _PatientDueDateTabState();
}

class _PatientDueDateTabState extends State<_PatientDueDateTab> {
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  String _trimester(int week) {
    if (week <= 12) return '1st Trimester';
    if (week <= 27) return '2nd Trimester';
    return '3rd Trimester';
  }

  int _currentWeek(DateTime dueDate) {
    final conceptionDate = dueDate.subtract(const Duration(days: 280));
    final weeks = DateTime.now().difference(conceptionDate).inDays ~/ 7;
    return weeks.clamp(1, 40);
  }

  int _daysLeft(DateTime dueDate) {
    final days = dueDate.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  Future<void> _saveRecord(String patientName, String patientId,
      DateTime dueDate, int week, String trimester, int days) async {
    await FirebaseFirestore.instance.collection('due_date_records').add({
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'dueDate': Timestamp.fromDate(dueDate),
      'currentWeek': week,
      'trimester': trimester,
      'daysLeft': days,
      'savedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record saved!'),
          backgroundColor: Color(0xFF185FA5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_requests')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (ctx, reqSnap) {
        if (!reqSnap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF185FA5)));
        }
        final requests = reqSnap.data!.docs;
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No active patients yet.',
                    style: TextStyle(color: Color(0xFF888780))),
                SizedBox(height: 4),
                Text('Accept patient requests to see their due dates.',
                    style:
                        TextStyle(color: Color(0xFFB4B2A9), fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (ctx, i) {
            final reqData =
                requests[i].data() as Map<String, dynamic>;
            final patientId = reqData['patientId'] as String;
            final patientName = reqData['patientName'] ?? 'Patient';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(patientId)
                  .get(),
              builder: (ctx, userSnap) {
                if (!userSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(color: Color(0xFF185FA5)),
                  );
                }

                final userData =
                    userSnap.data!.data() as Map<String, dynamic>?;
                final dueDateTs = userData?['dueDate'] as Timestamp?;

                if (dueDateTs == null) {
                  return _NoDueDateCard(patientName: patientName);
                }

                final dueDate = dueDateTs.toDate();
                final week = _currentWeek(dueDate);
                final trimester = _trimester(week);
                final days = _daysLeft(dueDate);
                final isPast = dueDate.isBefore(DateTime.now());

                return _DueDateCard(
                  patientName: patientName,
                  dueDate: dueDate,
                  week: week,
                  trimester: trimester,
                  daysLeft: days,
                  isPast: isPast,
                  onSave: () => _saveRecord(
                      patientName, patientId, dueDate, week, trimester, days),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DueDateCard extends StatelessWidget {
  final String patientName;
  final DateTime dueDate;
  final int week, daysLeft;
  final String trimester;
  final bool isPast;
  final VoidCallback onSave;

  const _DueDateCard({
    required this.patientName,
    required this.dueDate,
    required this.week,
    required this.trimester,
    required this.daysLeft,
    required this.isPast,
    required this.onSave,
  });

  Color get _progressColor {
    if (week <= 12) return const Color(0xFF4CAF50);
    if (week <= 27) return const Color(0xFF2196F3);
    return const Color(0xFFE8785A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE8E3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF185FA5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Text(
                    patientName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPast ? 'Delivered' : 'Week $week',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                if (!isPast) ...[
                  Row(
                    children: [
                      const Text('Progress',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888780))),
                      const Spacer(),
                      Text('${((week / 40) * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D3D3A))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (week / 40).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFECE8E3),
                      color: _progressColor,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Due Date',
                        value:
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                        icon: Icons.calendar_today_outlined,
                        color: const Color(0xFF185FA5),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: isPast ? 'Status' : 'Days Left',
                        value: isPast ? 'Past Due' : '$daysLeft days',
                        icon: Icons.timer_outlined,
                        color: isPast
                            ? const Color(0xFFA32D2D)
                            : const Color(0xFFE8785A),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Trimester',
                        value: trimester.replaceAll(' Trimester', ''),
                        icon: Icons.pregnant_woman,
                        color: _progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Trimester badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trimester,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _progressColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_outline, size: 16),
                    label: const Text('Save Record'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF185FA5),
                      side: const BorderSide(color: Color(0xFF185FA5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDueDateCard extends StatelessWidget {
  final String patientName;
  const _NoDueDateCard({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFFB4B2A9), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$patientName has not entered a due date.',
              style: const TextStyle(
                  color: Color(0xFF888780), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Color(0xFF888780))),
      ],
    );
  }
}

// ─── SAVED RECORDS TAB ────────────────────────────────────────────────────────

class _SavedRecordsTab extends StatelessWidget {
  const _SavedRecordsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('due_date_records')
          .where('doctorId', isEqualTo: uid)
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF185FA5)));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No saved records yet.',
                    style: TextStyle(color: Color(0xFF888780))),
                SizedBox(height: 4),
                Text('Tap "Save Record" on any patient card.',
                    style:
                        TextStyle(color: Color(0xFFB4B2A9), fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final due = (data['dueDate'] as Timestamp).toDate();
            final ts = data['savedAt'] as Timestamp?;
            final savedOn = ts != null
                ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFECE8E3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pregnant_woman,
                        color: Color(0xFF185FA5), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['patientName'] ?? 'Patient',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          'Due: ${due.day}/${due.month}/${due.year}  ·  Week ${data['currentWeek'] ?? '?'}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888780)),
                        ),
                        Text(
                          data['trimester'] ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF185FA5),
                              fontWeight: FontWeight.w500),
                        ),
                        if (savedOn.isNotEmpty)
                          Text(
                            'Saved on $savedOn',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFFB4B2A9)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFA32D2D), size: 20),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('due_date_records')
                        .doc(docs[i].id)
                        .delete(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
