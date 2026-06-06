import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/caretaker_provider.dart';
import '../login_screen.dart';
import 'caretaker_medications_tab.dart';
import 'caretaker_reports_tab.dart';
import 'caretaker_tests_tab.dart';

class CaretakerHomeScreen extends StatefulWidget {
  const CaretakerHomeScreen({super.key});

  @override
  State<CaretakerHomeScreen> createState() => _CaretakerHomeScreenState();
}

class _CaretakerHomeScreenState extends State<CaretakerHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Provider.of<CaretakerProvider>(context, listen: false).clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CaretakerProvider>(context);
    final patientName =
        provider.caretakerData?['linkedPatientName'] ?? 'Patient';
    final caretakerName = provider.caretakerName;
    final patientId = provider.linkedPatientId;

    if (patientId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDF8F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_off_rounded,
                  size: 64, color: Color(0xFFB4B2A9)),
              const SizedBox(height: 16),
              const Text('No patient linked to this account.',
                  style: TextStyle(color: Color(0xFF888780))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $caretakerName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Viewing: $patientName',
                style:
                    const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.medication_outlined, size: 18), text: 'Medications'),
            Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Reports'),
            Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Tests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CaretakerMedicationsTab(patientId: patientId),
          CaretakerReportsTab(patientId: patientId),
          CaretakerTestsTab(patientId: patientId),
        ],
      ),
    );
  }
}
