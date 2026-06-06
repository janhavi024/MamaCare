import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/doctor_provider.dart';
import 'login_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_due_date_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _DoctorDashboard(),
      const DoctorPatientsScreen(),
      const DoctorDueDateScreen(),
      const DoctorProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        selectedItemColor: const Color(0xFF185FA5),
        unselectedItemColor: const Color(0xFFB4B2A9),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate_rounded), label: 'Due Date'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DoctorDashboard extends StatelessWidget {
  const _DoctorDashboard();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);
    final name = provider.doctorName;
    final spec = provider.specialization;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 130,
          pinned: true,
          backgroundColor: const Color(0xFF185FA5),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                provider.clear();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: const Color(0xFF185FA5),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Good morning,',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Dr. $name',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  if (spec.isNotEmpty)
                    Text(spec,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending Requests Summary
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctor_requests')
                      .where('doctorId', isEqualTo: uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (ctx, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD966)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              color: Color(0xFF856404)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have $count pending patient request${count > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Color(0xFF856404),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Text('Overview',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3A))),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Active Patients',
                        icon: Icons.people_alt_rounded,
                        bg: const Color(0xFFE6F1FB),
                        color: const Color(0xFF185FA5),
                        stream: FirebaseFirestore.instance
                            .collection('doctor_requests')
                            .where('doctorId', isEqualTo: uid)
                            .where('status', isEqualTo: 'accepted')
                            .snapshots(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Pending Requests',
                        icon: Icons.pending_actions_rounded,
                        bg: const Color(0xFFFFF3CD),
                        color: const Color(0xFF856404),
                        stream: FirebaseFirestore.instance
                            .collection('doctor_requests')
                            .where('doctorId', isEqualTo: uid)
                            .where('status', isEqualTo: 'pending')
                            .snapshots(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Appointments',
                        icon: Icons.calendar_month_rounded,
                        bg: const Color(0xFFEAF3DE),
                        color: const Color(0xFF3B6D11),
                        stream: FirebaseFirestore.instance
                            .collection('appointments')
                            .where('doctorId', isEqualTo: uid)
                            .snapshots(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Reports Posted',
                        icon: Icons.insert_drive_file_rounded,
                        bg: const Color(0xFFFBEAF0),
                        color: const Color(0xFFA32D2D),
                        stream: FirebaseFirestore.instance
                            .collection('reports')
                            .where('doctorId', isEqualTo: uid)
                            .snapshots(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Upcoming Appointments
                const Text('Upcoming Appointments',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3A))),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('doctorId', isEqualTo: uid)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const SizedBox();
                    final allDocs = snap.data?.docs ?? [];
                    final now = DateTime.now();
                    final docs = allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final ts = data['dateTime'] as Timestamp?;
                      return ts != null && ts.toDate().isAfter(now);
                    }).take(3).toList();
                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFECE8E3)),
                        ),
                        child: const Center(
                          child: Text('No upcoming appointments',
                              style: TextStyle(color: Color(0xFF888780))),
                        ),
                      );
                    }
                    return Column(
                      children: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final dt = (data['dateTime'] as Timestamp).toDate();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${dt.day}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF185FA5))),
                                    Text(
                                      _monthAbbr(dt.month),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF185FA5)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['patientName'] ?? 'Patient',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(
                                      '${_timeStr(dt)} — ${data['notes'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888780)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.bg,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFECE8E3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF888780))),
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D3D3A))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
