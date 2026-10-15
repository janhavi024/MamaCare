import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Medication list + reminders. role: PATIENT (own data, reminders, mark taken), DOCTOR (prescribe), CARETAKER (read only).
class MedicationsView extends StatefulWidget {
  final int patientId;
  final String role;
  const MedicationsView({super.key, required this.patientId, required this.role});
  @override
  State<MedicationsView> createState() => _MedicationsViewState();
}

class _MedicationsViewState extends State<MedicationsView> {
  int _version = 0;
  bool get _patient => widget.role == 'PATIENT';

  Future<void> _changed() async {
    setState(() => _version++);
    if (_patient) {
      try {
        final p = context.read<PatientProvider>();
        await p.resyncReminders(); // re-schedule local notifications
        p.load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    final myId = context.read<AuthProvider>().user!.id;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.role == 'CARETAKER'
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.lavenderDark,
              foregroundColor: Colors.white,
              onPressed: () => _addSheet(context, s),
              icon: const Icon(Icons.add),
              label: Text(_patient ? 'Add medicine' : 'Prescribe'),
            ),
      body: AsyncBody<(List<Medication>, List<Dose>)>(
        key: ValueKey(_version),
        load: () async => (await s.medications.list(widget.patientId), await s.medications.today(widget.patientId)),
        builder: (context, data, reload) {
          final meds = data.$1;
          final doses = data.$2;
          final active = meds.where((m) => m.active).toList();
          if (meds.isEmpty) return EmptyView(icon: Icons.medication_outlined, text: _patient ? 'No medicines added yet.\nAdd what your doctor has prescribed and set reminders.' : 'No medications recorded.');
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [
              const Disclaimer('MamaCare only records medicines entered by you or your doctor. It never recommends or changes medication. Ask your doctor or pharmacist before taking anything.'),
              if (doses.isNotEmpty) ...[
                const SectionTitle('Today'),
                for (final d in doses)
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: CheckboxListTile(
                      value: d.taken,
                      onChanged: _patient ? (_) async { if (await guarded(context, () => d.taken ? s.medications.undo(d.reminderId) : s.medications.complete(d.reminderId))) _changed(); } : null,
                      title: Text('${d.medicationName} · ${d.dosage}'),
                      subtitle: Text(fmtTimeOfDay(d.timeOfDay)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
              ],
              const SectionTitle('All medicines'),
              for (final m in meds)
                Opacity(
                  opacity: m.active ? 1 : 0.5,
                  child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(m.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                        if (!m.active) const StatusChip('ARCHIVED') else if (m.byDoctor) const Chip(label: Text('Prescribed'), visualDensity: VisualDensity.compact),
                        if (m.active && ((_patient && !m.byDoctor) || (widget.role == 'DOCTOR' && m.prescribedById == myId)))
                          IconButton(
                            tooltip: 'Archive',
                            icon: const Icon(Icons.archive_outlined),
                            onPressed: () async {
                              if (await confirm(context, 'Archive ${m.name}?', 'It will no longer appear in today\'s reminders.', ok: 'Archive')) {
                                if (!context.mounted) return;
                                if (await guarded(context, () => s.medications.archive(m.id))) _changed();
                              }
                            },
                          ),
                      ]),
                      Text('${m.dosage} · ${m.frequency}', style: const TextStyle(color: AppColors.muted)),
                      if (m.instructions != null) Text(m.instructions!),
                      if (m.prescribedByName != null) Text('By Dr ${m.prescribedByName}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      if (m.active && (m.reminders.isNotEmpty || _patient)) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          for (final r in m.reminders)
                            InputChip(
                              avatar: Icon(r.enabled ? Icons.alarm_on : Icons.alarm_off, size: 18),
                              label: Text(fmtTimeOfDay(r.timeOfDay)),
                              onPressed: _patient ? () async { if (await guarded(context, () => s.medications.toggleReminder(r.id, !r.enabled))) _changed(); } : null,
                              onDeleted: _patient ? () async { if (await guarded(context, () => s.medications.deleteReminder(r.id))) _changed(); } : null,
                            ),
                          if (_patient)
                            ActionChip(
                              avatar: const Icon(Icons.add_alarm, size: 18),
                              label: const Text('Add reminder'),
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                                if (t == null || !context.mounted) return;
                                final hhmm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                                if (await guarded(context, () => s.medications.addReminder(m.id, hhmm), success: 'Reminder added')) _changed();
                              },
                            ),
                        ]),
                      ],
                    ]),
                  ),
                ),
              if (active.isEmpty) const Text('No active medicines.', style: TextStyle(color: AppColors.muted)),
            ]),
          );
        },
      ),
    );
  }

  void _addSheet(BuildContext context, Services s) {
    final name = TextEditingController();
    final dosage = TextEditingController();
    final instr = TextEditingController();
    String freq = 'Once daily';
    final times = <String>[];
    showFormSheet(context, title: _patient ? 'Add a medicine' : 'Prescribe a medicine', builder: (c) => StatefulBuilder(builder: (c, setState) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Disclaimer(_patient ? 'Only enter medicines your doctor has prescribed or approved.' : 'This is recorded as prescribed by you and is visible to the patient.'),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Medicine name')),
            const SizedBox(height: 12),
            TextField(controller: dosage, decoration: const InputDecoration(labelText: 'Dosage (as prescribed, e.g. 5 mg)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: freq,
              decoration: const InputDecoration(labelText: 'Schedule'),
              items: [for (final f in ['Once daily', 'Twice daily', 'Three times daily', 'Weekly', 'As directed']) DropdownMenuItem(value: f, child: Text(f))],
              onChanged: (v) => setState(() => freq = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: instr, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions (optional)')),
            if (_patient) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                for (final t in times) InputChip(label: Text(fmtTimeOfDay(t)), onDeleted: () => setState(() => times.remove(t))),
                ActionChip(
                  avatar: const Icon(Icons.add_alarm, size: 18),
                  label: const Text('Reminder time'),
                  onPressed: () async {
                    final t = await showTimePicker(context: c, initialTime: const TimeOfDay(hour: 8, minute: 0));
                    if (t == null) return;
                    final hhmm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    if (!times.contains(hhmm)) setState(() => times.add(hhmm));
                  },
                ),
              ]),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || dosage.text.trim().isEmpty) return showSnack(c, 'Name and dosage are required', error: true);
                final ok = await guarded(c, () => s.medications.create(widget.patientId, {
                      'name': name.text.trim(),
                      'dosage': dosage.text.trim(),
                      'frequency': freq,
                      'instructions': instr.text.trim().isEmpty ? null : instr.text.trim(),
                      'startDate': isoDate(DateTime.now()),
                      'reminderTimes': times,
                    }), success: 'Saved');
                if (ok) {
                  if (c.mounted) Navigator.pop(c);
                  _changed();
                }
              },
              child: const Text('Save'),
            ),
          ]);
        }));
  }
}
