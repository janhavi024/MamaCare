import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../patient/appointments_view.dart';
import '../patient/health_view.dart';
import '../patient/medications_view.dart';
import '../patient/records_view.dart';
import '../patient/progress_card.dart';

/// Caretakers see only patients who consented, and only the categories the patient ticked.
class CaretakerShell extends StatefulWidget {
  const CaretakerShell({super.key});
  @override
  State<CaretakerShell> createState() => _CaretakerShellState();
}

class _CaretakerShellState extends State<CaretakerShell> {
  int _v = 0;

  void _request() {
    final email = TextEditingController();
    final s = context.read<Services>();
    showFormSheet(context, title: 'Ask a mother for access', builder: (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Enter the e-mail she registered with. She will see your request and choose what you can see.', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Her email')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              String? msg;
              final ok = await guarded(c, () async => msg = await s.caretakers.request(email.text.trim()));
              if (ok) {
                if (c.mounted) Navigator.pop(c);
                if (mounted) {
                  showSnack(context, msg ?? 'Request sent');
                  setState(() => _v++);
                }
              }
            },
            child: const Text('Send request'),
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    final me = context.watch<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(title: Text('Hello, ${me.fullName.split(' ').first}'), actions: [
        IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: () => context.read<AuthProvider>().logout()),
      ]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppColors.lavenderDark, foregroundColor: Colors.white, onPressed: _request, icon: const Icon(Icons.person_add_alt), label: const Text('Request access')),
      body: AsyncBody<List<Map<String, dynamic>>>(
        key: ValueKey(_v),
        load: () => s.caretakers.myPatients(),
        builder: (context, list, reload) => list.isEmpty
            ? const EmptyView(icon: Icons.family_restroom, text: 'You are not connected to anyone yet.\nTap "Request access" and enter the mother\'s email.')
            : RefreshIndicator(
                onRefresh: reload,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
                  for (final a in list)
                    AppCard(
                      onTap: a['status'] == 'GRANTED' ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PatientView(access: a))) : null,
                      child: Row(children: [
                        AvatarCircle(initials(a['patientName'])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a['patientName'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(switch (a['status']) {
                            'PENDING' => 'Waiting for her approval',
                            'GRANTED' => 'Tap to view shared information',
                            'REJECTED' => 'Request declined',
                            _ => 'Access ended',
                          }, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        ])),
                        StatusChip(a['status']),
                        if (a['status'] == 'GRANTED')
                          IconButton(
                            tooltip: 'Stop having access',
                            icon: const Icon(Icons.link_off),
                            onPressed: () async {
                              if (await confirm(context, 'Leave this patient?', 'You will lose access until she approves a new request.', ok: 'Leave')) {
                                if (!context.mounted) return;
                                if (await guarded(context, () => s.caretakers.leave(a['id']))) setState(() => _v++);
                              }
                            },
                          ),
                      ]),
                    ),
                ]),
              ),
      ),
    );
  }
}

class _PatientView extends StatelessWidget {
  final Map<String, dynamic> access;
  const _PatientView({required this.access});

  @override
  Widget build(BuildContext context) {
    final id = access['patientId'] as int;
    final tabs = <(String, Widget)>[
      ('Progress', ProgressCard(patientId: id)),
      if (access['canViewHealth'] == true) ('Health', HealthView(patientId: id, readOnly: true)),
      if (access['canViewMedications'] == true) ('Medications', MedicationsView(patientId: id, role: 'CARETAKER')),
      if (access['canViewAppointments'] == true) ('Appointments', AppointmentsView(forPatientId: id)),
      if (access['canViewRecords'] == true) ('Records', RecordsView(patientId: id, canWrite: false)),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(title: Text(access['patientName']), bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final t in tabs) Tab(text: t.$1)])),
        body: TabBarView(children: [for (final t in tabs) t.$2]),
      ),
    );
  }
}
