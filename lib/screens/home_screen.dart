import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../data/baby_week_data.dart';
import 'login_screen.dart';
import 'medication_screen.dart';
import 'mood_screen.dart';
import 'tests_screen.dart';
import 'doctor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    MedicationScreen(),
    MoodScreen(),
    TestsScreen(),
    DoctorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        selectedItemColor: const Color(0xFFE8785A),
        unselectedItemColor: const Color(0xFFB4B2A9),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.mood_rounded), label: 'Mood'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Tests'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_rounded), label: 'Doctor'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final week = provider.currentWeek;
    final babyData = getBabyDataForWeek(week);
    final name = provider.motherName;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xFFE8785A),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: const Color(0xFFE8785A),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning,',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                      Text(name,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Week $week',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text('Sign out',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _BabyCard(babyData: babyData),
                const SizedBox(height: 16),
                _TodayStats(),
                const SizedBox(height: 16),
                _MoodCheckIn(),
                const SizedBox(height: 16),
                _WeeklyReminder(week: week),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BabyCard extends StatelessWidget {
  final BabyWeekData babyData;
  const _BabyCard({required this.babyData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0DDD5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.child_care, color: Color(0xFFE8785A), size: 18),
              SizedBox(width: 8),
              Text('Your baby this week',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF3D3D3A))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  babyData.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.child_care, color: Color(0xFFE8785A), size: 48),
                  ),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFFE8785A))),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Size of a ${babyData.fruit}',
                        style: const TextStyle(
                          color: Color(0xFF993C1D),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${babyData.size} long',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      babyData.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888780), height: 1.5),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final medsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('medications');
    final testsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tests');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s health',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF3D3D3A))),
        const SizedBox(height: 10),
        Row(
          children: [
            // Meds taken vs total
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: medsRef.snapshots(),
                builder: (ctx, snap) {
                  final docs = snap.data?.docs ?? [];
                  final total = docs.length;
                  final taken = docs.where((d) => (d.data() as Map)['taken'] == true).length;
                  return _StatCard(
                    label: 'Meds taken',
                    value: total == 0 ? '—' : '$taken of $total',
                    icon: Icons.medication_outlined,
                    bg: const Color(0xFFEAF3DE),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Next upcoming test
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: testsRef.snapshots(),
                builder: (ctx, snap) {
                  final docs = snap.data?.docs ?? [];
                  final now = DateTime.now();
                  DateTime? nearest;
                  for (final d in docs) {
                    final data = d.data() as Map<String, dynamic>;
                    if (data['done'] == true) continue;
                    final ts = data['date'];
                    if (ts == null) continue;
                    final dt = (ts as Timestamp).toDate();
                    if (dt.isAfter(now)) {
                      if (nearest == null || dt.isBefore(nearest)) nearest = dt;
                    }
                  }
                  String value;
                  if (nearest == null) {
                    value = 'None';
                  } else {
                    final days = nearest.difference(now).inDays;
                    value = days == 0 ? 'Today' : '$days days';
                  }
                  return _StatCard(
                    label: 'Next test',
                    value: value,
                    icon: Icons.calendar_today_outlined,
                    bg: const Color(0xFFFAEEDA),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Today's mood
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .collection('moods')
              .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
              .snapshots(),
          builder: (ctx, snap) {
            String moodValue = 'Not logged';
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>;
              moodValue = '${data['emoji'] ?? ''} ${data['label'] ?? ''}';
            }
            return _StatCard(
              label: 'Today\'s mood',
              value: moodValue,
              icon: Icons.mood_rounded,
              bg: const Color(0xFFFBEAF0),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color bg;
  const _StatCard({required this.label, required this.value, required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, size: 18, color: const Color(0xFF3D3D3A)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D3D3A))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodCheckIn extends StatefulWidget {
  @override
  State<_MoodCheckIn> createState() => _MoodCheckInState();
}

class _MoodCheckInState extends State<_MoodCheckIn> {
  int? _selectedMood;
  final moods = ['😢', '😐', '😊', '😄'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('How are you feeling?',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF3D3D3A))),
          Row(
            children: List.generate(moods.length, (i) {
              final selected = _selectedMood == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = i),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFEF3EE) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? const Color(0xFFE8785A) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(child: Text(moods[i], style: const TextStyle(fontSize: 18))),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeeklyReminder extends StatelessWidget {
  final int week;
  const _WeeklyReminder({required this.week});

  String _getReminderText() {
    if (week >= 24 && week <= 28) return 'Glucose tolerance test due this week';
    if (week >= 18 && week <= 22) return 'Anatomy scan ultrasound recommended';
    if (week >= 35) return 'Weekly checkups starting now — stay close!';
    if (week >= 28) return 'Rh factor test may be needed';
    return 'Stay hydrated and take your prenatal vitamins!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC0DD97)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFC0DD97),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: Color(0xFF27500A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Week reminder',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF27500A))),
                const SizedBox(height: 2),
                Text(_getReminderText(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF3B6D11))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
