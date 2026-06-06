import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'login_screen.dart';
import 'admin/admin_doctors_screen.dart';
import 'admin/admin_patients_screen.dart';
import 'admin/admin_pending_doctors_screen.dart';
import 'admin/admin_pending_patients_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _AdminDashboard(),
      const AdminPendingDoctorsScreen(),
      const AdminPendingPatientsScreen(),
      const AdminDoctorsScreen(),
      const AdminPatientsScreen(),
    ];

    return Scaffold(
      body: screens[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        selectedItemColor: const Color(0xFF6C3483),
        unselectedItemColor: const Color(0xFFB4B2A9),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_rounded),
              label: 'Dr. Requests'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pregnant_woman_rounded),
              label: 'Pt. Requests'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Doctors'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded), label: 'Patients'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final name = provider.adminName;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 130,
          pinned: true,
          backgroundColor: const Color(0xFF6C3483),
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
              color: const Color(0xFF6C3483),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Panel',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Text('Full system access',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
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
                // Pending alerts banner
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctors')
                      .where('approvalStatus', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (ctx, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox();
                    return _AlertBanner(
                      message:
                          '$count pending doctor registration${count > 1 ? 's' : ''} awaiting approval',
                      icon: Icons.medical_services_rounded,
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('approvalStatus', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (ctx, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox();
                    return _AlertBanner(
                      message:
                          '$count pending patient registration${count > 1 ? 's' : ''} awaiting approval',
                      icon: Icons.pregnant_woman_rounded,
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
                        label: 'Total Doctors',
                        icon: Icons.medical_services_rounded,
                        bg: const Color(0xFFE6F1FB),
                        color: const Color(0xFF185FA5),
                        stream: FirebaseFirestore.instance
                            .collection('doctors')
                            .snapshots(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Total Patients',
                        icon: Icons.group_rounded,
                        bg: const Color(0xFFFBEAF0),
                        color: const Color(0xFFE8785A),
                        stream: FirebaseFirestore.instance
                            .collection('users')
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
                        label: 'Pending Doctors',
                        icon: Icons.pending_actions_rounded,
                        bg: const Color(0xFFFFF3CD),
                        color: const Color(0xFF856404),
                        stream: FirebaseFirestore.instance
                            .collection('doctors')
                            .where('approvalStatus', isEqualTo: 'pending')
                            .snapshots(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Pending Patients',
                        icon: Icons.pending_rounded,
                        bg: const Color(0xFFEAF3DE),
                        color: const Color(0xFF3B6D11),
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('approvalStatus', isEqualTo: 'pending')
                            .snapshots(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3A))),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        label: 'Doctor\nRequests',
                        icon: Icons.medical_services_rounded,
                        color: const Color(0xFF185FA5),
                        onTap: () {
                          // Navigate to tab index 1
                          final state = context
                              .findAncestorStateOfType<
                                  _AdminHomeScreenState>();
                          state?.setState(() => state._currentTab = 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        label: 'Patient\nRequests',
                        icon: Icons.pregnant_woman_rounded,
                        color: const Color(0xFFE8785A),
                        onTap: () {
                          final state = context
                              .findAncestorStateOfType<
                                  _AdminHomeScreenState>();
                          state?.setState(() => state._currentTab = 2);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        label: 'All\nDoctors',
                        icon: Icons.people_rounded,
                        color: const Color(0xFF6C3483),
                        onTap: () {
                          final state = context
                              .findAncestorStateOfType<
                                  _AdminHomeScreenState>();
                          state?.setState(() => state._currentTab = 3);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        label: 'All\nPatients',
                        icon: Icons.group_rounded,
                        color: const Color(0xFF3B6D11),
                        onTap: () {
                          final state = context
                              .findAncestorStateOfType<
                                  _AdminHomeScreenState>();
                          state?.setState(() => state._currentTab = 4);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const _AlertBanner({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD966)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF856404), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFF856404), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF888780))),
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

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECE8E3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
