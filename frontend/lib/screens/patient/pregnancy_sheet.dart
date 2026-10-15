import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../providers/patient_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Create (or edit) the pregnancy profile: either the due date, or the first day of the last period.
Future<void> showPregnancySheet(BuildContext context, {bool editing = false}) {
  final provider = context.read<PatientProvider>();
  final services = context.read<Services>();
  DateTime? due;
  DateTime? lmp;
  return showFormSheet(context, title: editing ? 'Update pregnancy details' : 'Add your pregnancy', builder: (c) {
    return StatefulBuilder(builder: (c, setState) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Enter your due date if you know it, or the first day of your last period and we will estimate it (40 weeks). Your doctor can confirm the date later.',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text(due == null ? 'Choose due date' : 'Due date: ${fmtDate(due!)}'),
          onPressed: () async {
            final d = await pickDate(c, initial: due ?? DateTime.now().add(const Duration(days: 140)), first: DateTime.now().subtract(const Duration(days: 14)), last: DateTime.now().add(const Duration(days: 280)));
            if (d != null) setState(() => due = d);
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month),
          label: Text(lmp == null ? 'Or first day of last period' : 'Last period: ${fmtDate(lmp!)}'),
          onPressed: () async {
            final d = await pickDate(c, initial: lmp ?? DateTime.now().subtract(const Duration(days: 60)), first: DateTime.now().subtract(const Duration(days: 294)), last: DateTime.now());
            if (d != null) setState(() => lmp = d);
          },
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            if (due == null && lmp == null) {
              showSnack(c, 'Please choose a date', error: true);
              return;
            }
            final body = {'dueDate': due == null ? null : isoDate(due!), 'lmpDate': lmp == null ? null : isoDate(lmp!)};
            final ok = await guarded(c, () => editing ? services.patient.updatePregnancy(body) : services.patient.createPregnancy(body), success: 'Pregnancy saved');
            if (ok) {
              await provider.load();
              if (c.mounted) Navigator.pop(c);
            }
          },
          child: const Text('Save'),
        ),
      ]);
    });
  });
}
