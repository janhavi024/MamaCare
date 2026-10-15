import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import '../patient/appointments_view.dart';
import '../patient/health_view.dart';
import '../patient/medications_view.dart';
import '../patient/records_view.dart';

/// A doctor's view of ONE linked patient. The server re-checks the link on every request below.
class DoctorPatientScreen extends StatelessWidget {
  final int patientId;
  final String patientName;
  const DoctorPatientScreen({super.key, required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(patientName),
            bottom: const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
              Tab(text: 'Overview'), Tab(text: 'Health'), Tab(text: 'Medications'), Tab(text: 'Records'), Tab(text: 'Appointments'),
            ]),
          ),
          body: TabBarView(children: [
            _Overview(patientId: patientId),
            HealthView(patientId: patientId, readOnly: true),
            MedicationsView(patientId: patientId, role: 'DOCTOR'),
            RecordsView(patientId: patientId, canWrite: true),
            AppointmentsView(forPatientId: patientId),
          ]),
        ),
      );
}

class _Overview extends StatefulWidget {
  final int patientId;
  const _Overview({required this.patientId});
  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  int _v = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return AsyncBody<(Progress, Map<String, dynamic>)>(
      key: ValueKey(_v),
      load: () async => (await s.patient.progress(widget.patientId), await s.patient.profile(widget.patientId)),
      builder: (context, data, reload) {
        final p = data.$1;
        final prof = data.$2;
        return ListView(padding: const EdgeInsets.all(16), children: [
          AppCard(child: Column(children: [
            _kv('Email', prof['email']),
            _kv('Phone', prof['phone']),
            _kv('Date of birth', prof['dateOfBirth']),
            _kv('Blood group', prof['bloodGroup']),
            _kv('Emergency contact', prof['emergencyContactName'] == null ? null : '${prof['emergencyContactName']} ${prof['emergencyContactPhone'] ?? ''}'),
          ])),
          const SectionTitle('Pregnancy'),
          AppCard(child: !p.hasPregnancy
              ? const Text('No active pregnancy recorded.')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Week ${p.currentWeek} of 40 · Trimester ${p.trimester}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Due ${fmtDate(p.dueDate!)} (${p.dueDateSource == 'DOCTOR_CONFIRMED' ? 'doctor-confirmed' : p.dueDateSource == 'LMP_CALCULATED' ? 'calculated from last period' : 'self-reported'})', style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 12),
                  WeekTrack(week: p.currentWeek),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Confirm due date'),
                    onPressed: () async {
                      final d = await pickDate(context, initial: p.dueDate, first: DateTime.now().subtract(const Duration(days: 14)), last: DateTime.now().add(const Duration(days: 280)));
                      if (d == null || !context.mounted) return;
                      if (await guarded(context, () => s.doctors.confirmDueDate(widget.patientId, d), success: 'Due date confirmed')) setState(() => _v++);
                    },
                  ),
                ])),
          const SizedBox(height: 4),
          FilledButton.icon(
            icon: const Icon(Icons.event),
            label: const Text('Schedule an appointment'),
            onPressed: () => showBookSheet(context, patientId: widget.patientId),
          ),
          const Disclaimer('Readings and notes entered by the patient are self-reported. Clinical decisions remain yours.'),
        ]);
      },
    );
  }

  Widget _kv(String k, Object? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: AppColors.muted))),
          Expanded(child: Text(v == null || '$v'.trim().isEmpty ? '—' : '$v', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
