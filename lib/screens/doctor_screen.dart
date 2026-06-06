import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Patient-facing doctor screen — browse doctors, send requests,
/// view reports, appointments & medications from your doctor.
class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Doctors'),
        backgroundColor: const Color(0xFFE8785A),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Find Doctors'),
            Tab(text: 'My Reports'),
            Tab(text: 'Appointments'),
            Tab(text: 'Medications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FindDoctorsTab(),
          _PatientReportsTab(),
          _PatientAppointmentsTab(),
          _PatientMedicationsTab(),
        ],
      ),
    );
  }
}

// ─── FIND DOCTORS TAB ────────────────────────────────────────────────────────

class _FindDoctorsTab extends StatefulWidget {
  const _FindDoctorsTab();

  @override
  State<_FindDoctorsTab> createState() => _FindDoctorsTabState();
}

class _FindDoctorsTabState extends State<_FindDoctorsTab> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _msgCtrl = TextEditingController();

  Future<void> _sendRequest(
      BuildContext context, Map<String, dynamic> doctor, String doctorId) async {
    final provider = Provider.of<UserProvider>(context, listen: false);

    // Check if already sent
    final existing = await FirebaseFirestore.instance
        .collection('doctor_requests')
        .where('patientId', isEqualTo: uid)
        .where('doctorId', isEqualTo: doctorId)
        .get();
    if (existing.docs.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already sent a request to this doctor.'),
          backgroundColor: Color(0xFFE8785A),
        ),
      );
      return;
    }

    _msgCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Dr. ${doctor['name']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a message (optional)',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('doctor_requests')
                      .add({
                    'patientId': uid,
                    'patientName': provider.motherName,
                    'patientEmail': FirebaseAuth.instance.currentUser?.email ?? '',
                    'doctorId': doctorId,
                    'doctorName': doctor['name'],
                    'message': _msgCtrl.text.trim(),
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request sent successfully!'),
                        backgroundColor: Color(0xFF3B6D11),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8785A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .where('approvalStatus', isEqualTo: 'approved')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8785A)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No doctors registered yet.',
                style: TextStyle(color: Color(0xFF888780))),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final doctorId = docs[i].id;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctor_requests')
                  .where('patientId', isEqualTo: uid)
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (ctx, reqSnap) {
                String? reqStatus;
                if (reqSnap.hasData && reqSnap.data!.docs.isNotEmpty) {
                  reqStatus = (reqSnap.data!.docs.first.data()
                      as Map<String, dynamic>)['status'];
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECE8E3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFE6F1FB),
                            child: Text(
                              (data['name'] ?? 'D')[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF185FA5)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dr. ${data['name'] ?? ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(data['specialization'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF185FA5))),
                              ],
                            ),
                          ),
                          if (reqStatus != null)
                            _statusBadge(reqStatus),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (data['hospital'] != null &&
                          data['hospital'].toString().isNotEmpty)
                        _InfoRow(
                            Icons.local_hospital_outlined,
                            data['hospital']),
                      _InfoRow(Icons.email_outlined, data['email'] ?? ''),
                      _InfoRow(
                          Icons.work_outline,
                          '${data['yearsOfExperience'] ?? 0} years experience'),
                      _InfoRow(
                          Icons.school_outlined,
                          data['qualification'] ?? ''),
                      if (data['bio'] != null &&
                          data['bio'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(data['bio'],
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888780),
                                fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 12),
                      if (reqStatus == null)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => _sendRequest(context, data, doctorId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8785A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Send Request'),
                          ),
                        )
                      else if (reqStatus == 'rejected')
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () => _sendRequest(context, data, doctorId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE8785A),
                              side: const BorderSide(color: Color(0xFFE8785A)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFEAF3DE);
        fg = const Color(0xFF3B6D11);
        label = 'Connected';
        break;
      case 'pending':
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF856404);
        label = 'Pending';
        break;
      default:
        bg = const Color(0xFFFCEBEB);
        fg = const Color(0xFFA32D2D);
        label = 'Declined';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFB4B2A9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF888780))),
          ),
        ],
      ),
    );
  }
}

// ─── PATIENT REPORTS TAB ─────────────────────────────────────────────────────

class _PatientReportsTab extends StatelessWidget {
  const _PatientReportsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8785A)));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error loading reports: ${snap.error}',
                style: const TextStyle(color: Color(0xFF888780))),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No reports from your doctor yet.',
                    style: TextStyle(color: Color(0xFF888780))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ts = data['createdAt'] as Timestamp?;
            final date = ts != null
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(data['type'] ?? '',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE8785A),
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
                  if (data['notes'] != null &&
                      data['notes'].toString().isNotEmpty) ...[
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
    );
  }
}

// ─── PATIENT APPOINTMENTS TAB ─────────────────────────────────────────────────

class _PatientAppointmentsTab extends StatelessWidget {
  const _PatientAppointmentsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8785A)));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error loading appointments: ${snap.error}',
                style: const TextStyle(color: Color(0xFF888780))),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No appointments scheduled yet.',
                    style: TextStyle(color: Color(0xFF888780))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                        : const Color(0xFFE8785A),
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
                          : const Color(0xFFFEF3EE),
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
                                    : const Color(0xFFE8785A))),
                        Text(_monthAbbr(dt.month),
                            style: TextStyle(
                                fontSize: 10,
                                color: isPast
                                    ? const Color(0xFF888780)
                                    : const Color(0xFFE8785A))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. ${data['doctorName'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(_timeStr(dt),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888780))),
                        if (data['notes'] != null &&
                            data['notes'].toString().isNotEmpty)
                          Text(data['notes'],
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888780))),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPast
                          ? const Color(0xFFF0F0F0)
                          : const Color(0xFFFEF3EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPast ? 'Past' : 'Upcoming',
                      style: TextStyle(
                          fontSize: 10,
                          color: isPast
                              ? const Color(0xFF888780)
                              : const Color(0xFFE8785A),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

// ─── PATIENT MEDICATIONS TAB ──────────────────────────────────────────────────

class _PatientMedicationsTab extends StatelessWidget {
  const _PatientMedicationsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_medications')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8785A)));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error loading medications: ${snap.error}',
                style: const TextStyle(color: Color(0xFF888780))),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_outlined,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No medications prescribed yet.',
                    style: TextStyle(color: Color(0xFF888780))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 4),
                        Text('Prescribed by Dr. ${data['doctorName'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF888780))),
                      ],
                    ),
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
