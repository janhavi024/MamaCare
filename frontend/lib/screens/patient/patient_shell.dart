import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'assistant_screen.dart';
import 'dashboard_screen.dart';
import 'health_view.dart';
import 'journey_screen.dart';
import 'profile_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});
  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return ChangeNotifierProvider(
      create: (c) => PatientProvider(c.read<Services>(), user.id)..load(),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: [
          DashboardScreen(onNavigate: (i) => setState(() => _index = i)),
          const JourneyScreen(),
          Scaffold(
            appBar: AppBar(title: const Text('Health Monitor')),
            body: HealthView(patientId: user.id, readOnly: false),
          ),
          const AssistantScreen(),
          const ProfileScreen(),
        ]),
        bottomNavigationBar: PillNavBar(
          index: _index,
          icons: const [Icons.home_rounded, Icons.child_friendly_rounded, Icons.monitor_heart_rounded, Icons.auto_awesome_rounded, Icons.person_rounded],
          labels: const ['Home', 'Pregnancy journey', 'Health monitor', 'Assistant', 'Profile'],
          onTap: (i) {
            setState(() => _index = i);
            if (i == 0) context.read<PatientProvider>().load();
          },
        ),
      ),
    );
  }
}
