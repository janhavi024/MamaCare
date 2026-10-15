import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment a;
  final bool showPatient;
  final List<Widget> actions;
  const AppointmentCard({super.key, required this.a, this.showPatient = false, this.actions = const []});

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(backgroundColor: AppColors.lavenderSoft, child: Icon(Icons.event, color: AppColors.lavenderDark)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(showPatient ? a.patientName : 'Dr ${a.doctorName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(fmtDateTime(a.scheduledAt), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ])),
            StatusChip(a.status),
          ]),
          if (a.reason != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Reason: ${a.reason}')),
          if (a.doctorNote != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Doctor\'s note: ${a.doctorNote}', style: const TextStyle(fontStyle: FontStyle.italic))),
          if (actions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 8, children: actions)),
        ]),
      );
}

/// Patient's own appointments (or another patient's, when a doctor/caretaker passes forPatientId).
class AppointmentsView extends StatefulWidget {
  final int? forPatientId;
  final bool canBook;
  const AppointmentsView({super.key, this.forPatientId, this.canBook = false});
  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  int _version = 0;
  bool _upcoming = true;

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.canBook
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.lavenderDark,
              foregroundColor: Colors.white,
              onPressed: () async {
                if (await showBookSheet(context)) setState(() => _version++);
              },
              icon: const Icon(Icons.add),
              label: const Text('Book'),
            )
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('Upcoming')), ButtonSegment(value: false, label: Text('Past & closed'))],
            selected: {_upcoming},
            onSelectionChanged: (v) => setState(() => _upcoming = v.first),
          ),
        ),
        Expanded(
          child: AsyncBody<List<Appointment>>(
            key: ValueKey(_version),
            load: () => widget.forPatientId == null ? s.appointments.mine() : s.appointments.forPatient(widget.forPatientId!),
            builder: (context, all, reload) {
              final list = all.where((a) => a.isUpcoming == _upcoming).toList();
              if (!_upcoming) list.sort((x, y) => y.scheduledAt.compareTo(x.scheduledAt));
              if (list.isEmpty) return EmptyView(icon: Icons.event_available, text: _upcoming ? 'No upcoming appointments.' : 'Nothing here yet.');
              return RefreshIndicator(
                onRefresh: reload,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), children: [
                  for (final a in list)
                    AppointmentCard(
                      a: a,
                      showPatient: widget.forPatientId != null,
                      actions: [
                        if (widget.canBook && a.isUpcoming)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel appointment'),
                            onPressed: () async {
                              if (await confirm(context, 'Cancel this appointment?', 'The doctor will see it as cancelled.', ok: 'Cancel appointment')) {
                                if (!context.mounted) return;
                                if (await guarded(context, () => s.appointments.setStatus(a.id, 'CANCELLED'), success: 'Appointment cancelled')) setState(() => _version++);
                              }
                            },
                          ),
                      ],
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Booking form. Patients pick a verified doctor; doctors pass [patientId] to schedule for a linked patient.
/// Returns true when an appointment was created.
Future<bool> showBookSheet(BuildContext context, {Doctor? doctor, int? patientId}) async {
  final s = context.read<Services>();
  List<Doctor> doctors = [];
  if (patientId == null && doctor == null) {
    try {
      doctors = await s.doctors.directory();
    } catch (e) {
      if (context.mounted) showSnack(context, e.toString(), error: true);
      return false;
    }
    if (doctors.isEmpty) {
      if (context.mounted) showSnack(context, 'No verified doctors are available yet.', error: true);
      return false;
    }
  }
  if (!context.mounted) return false;
  Doctor? chosen = doctor ?? (doctors.isNotEmpty ? doctors.first : null);
  DateTime? date;
  TimeOfDay? time;
  final reason = TextEditingController();
  bool created = false;
  await showFormSheet(context, title: patientId == null ? 'Book an appointment' : 'Schedule an appointment', builder: (c) => StatefulBuilder(builder: (c, setState) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (patientId == null && doctor == null)
            DropdownButtonFormField<Doctor>(
              value: chosen,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Doctor'),
              items: [for (final d in doctors) DropdownMenuItem(value: d, child: Text('Dr ${d.fullName} · ${d.specialization}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => chosen = v),
            )
          else if (doctor != null)
            Text('Dr ${doctor.fullName} · ${doctor.specialization}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(date == null ? 'Date' : fmtDate(date!)),
                onPressed: () async {
                  final d = await pickDate(c, initial: DateTime.now().add(const Duration(days: 1)), first: DateTime.now(), last: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => date = d);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(time == null ? 'Time' : time!.format(c)),
                onPressed: () async {
                  final t = await showTimePicker(context: c, initialTime: const TimeOfDay(hour: 10, minute: 0));
                  if (t != null) setState(() => time = t);
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(controller: reason, maxLength: 300, decoration: const InputDecoration(labelText: 'Reason (optional)')),
          const SizedBox(height: 8),
          if (patientId == null) const Text('The doctor needs to confirm your request. Each appointment takes a 30-minute slot.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              if (date == null || time == null) return showSnack(c, 'Please choose a date and time', error: true);
              final at = DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);
              if (!at.isAfter(DateTime.now())) return showSnack(c, 'Choose a time in the future', error: true);
              final ok = await guarded(c, () => s.appointments.book(doctorId: patientId == null ? chosen!.id : null, patientId: patientId, at: at, reason: reason.text),
                  success: patientId == null ? 'Request sent' : 'Appointment scheduled');
              if (ok) {
                created = true;
                if (c.mounted) Navigator.pop(c);
              }
            },
            child: Text(patientId == null ? 'Request appointment' : 'Schedule'),
          ),
        ]);
      }));
  return created;
}
