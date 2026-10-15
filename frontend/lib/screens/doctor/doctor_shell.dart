import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../patient/appointments_view.dart';
import 'doctor_patient_screen.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});
  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _index = 0;
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['My patients', 'Patient requests', 'Appointments', 'My profile'];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(titles[_index])),
      body: KeyedSubtree(
        key: ValueKey('$_index-$_version'),
        child: [const _PatientsTab(), _RequestsTab(onChanged: () => setState(() => _version++)), const _AppointmentsTab(), const _ProfileTab()][_index],
      ),
      bottomNavigationBar: PillNavBar(
        index: _index,
        icons: const [Icons.groups_rounded, Icons.person_add_alt_1_rounded, Icons.event_note_rounded, Icons.badge_rounded],
        labels: titles,
        onTap: (i) => setState(() {
          _index = i;
          _version++;
        }),
      ),
    );
  }
}

class _PatientsTab extends StatelessWidget {
  const _PatientsTab();
  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return AsyncBody<List<Map<String, dynamic>>>(
      load: () => s.doctors.myPatients(),
      builder: (context, list, reload) => list.isEmpty
          ? const EmptyView(icon: Icons.groups_outlined, text: 'No patients yet.\nPatients appear here after you accept their request.')
          : RefreshIndicator(
              onRefresh: reload,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
                for (final p in list)
                  AppCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientScreen(patientId: p['patientId'], patientName: p['fullName']))),
                    child: Row(children: [
                      AvatarCircle(initials(p['fullName'])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['fullName'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(p['gestationalWeek'] == null ? 'No active pregnancy' : 'Week ${p['gestationalWeek'] + 1} · due ${fmtDate(DateTime.parse(p['dueDate']))}', style: const TextStyle(color: AppColors.muted)),
                      ])),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
              ]),
            ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final VoidCallback onChanged;
  const _RequestsTab({required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return AsyncBody<List<Map<String, dynamic>>>(
      load: () => s.doctors.links(status: 'PENDING'),
      builder: (context, list, reload) => list.isEmpty
          ? const EmptyView(icon: Icons.inbox_outlined, text: 'No pending requests.')
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
              const Disclaimer('Accepting gives the patient\'s data (pregnancy, readings, medicines, records) to you. Decline if you do not know the patient.'),
              for (final l in list)
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l['patientName'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    if (l['message'] != null) Text(l['message']),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: FilledButton(onPressed: () async { if (await guarded(context, () => s.doctors.decideLink(l['id'], 'ACCEPTED'), success: 'Patient accepted')) onChanged(); }, child: const Text('Accept'))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton(onPressed: () async { if (await guarded(context, () => s.doctors.decideLink(l['id'], 'DECLINED'))) onChanged(); }, child: const Text('Decline'))),
                    ]),
                  ]),
                ),
            ]),
    );
  }
}

class _AppointmentsTab extends StatefulWidget {
  const _AppointmentsTab();
  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  int _v = 0;

  Widget _btn(String label, Future<void> Function() f, {bool danger = false}) => OutlinedButton(
        style: danger ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger) : null,
        onPressed: () async { if (await guarded(context, f)) setState(() => _v++); },
        child: Text(label),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return AsyncBody<List<Appointment>>(
      key: ValueKey(_v),
      load: () => s.appointments.mine(),
      builder: (context, all, reload) {
        final list = all.where((a) => a.isActive).toList();
        if (list.isEmpty) return const EmptyView(icon: Icons.event_available, text: 'No open appointments.');
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
            for (final a in list)
              AppointmentCard(a: a, showPatient: true, actions: [
                if (a.status == 'REQUESTED') ...[
                  FilledButton(onPressed: () async { if (await guarded(context, () => s.appointments.setStatus(a.id, 'CONFIRMED'), success: 'Confirmed')) setState(() => _v++); }, child: const Text('Confirm')),
                  _btn('Decline', () => s.appointments.setStatus(a.id, 'DECLINED'), danger: true),
                ],
                if (a.status == 'CONFIRMED') ...[
                  _btn('Mark completed', () => s.appointments.setStatus(a.id, 'COMPLETED')),
                  _btn('Cancel', () => s.appointments.setStatus(a.id, 'CANCELLED'), danger: true),
                ],
              ]),
          ]),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return AsyncBody<Map<String, dynamic>>(
      load: () => s.doctors.me(),
      builder: (context, d, reload) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 120), children: [
        Row(children: [
          AvatarCircle(initials(d['fullName']), radius: 34),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr ${d['fullName']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(d['email'], style: const TextStyle(color: AppColors.muted)),
          ])),
          if (d['verificationStatus'] != null) StatusChip(d['verificationStatus']),
        ]),
        const SizedBox(height: 16),
        AppCard(child: Column(children: [
          _kv('Specialization', d['specialization']),
          _kv('Qualification', d['qualification']),
          _kv('Hospital', d['hospital']),
          _kv('License no.', d['licenseNumber']),
          _kv('Experience', d['yearsOfExperience'] == null ? null : '${d['yearsOfExperience']} years'),
          _kv('About', d['bio']),
        ])),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          onPressed: () => context.read<AuthProvider>().logout(),
        ),
      ]),
    );
  }

  static Widget _kv(String k, Object? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AppColors.muted))),
          Expanded(child: Text(v == null ? '—' : '$v', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
