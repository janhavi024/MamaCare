import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/patient_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

const Map<String, (String, String, IconData)> obsTypes = {
  'WEIGHT': ('Weight', 'kg', Icons.monitor_weight_outlined),
  'BLOOD_PRESSURE': ('Blood pressure', 'mmHg', Icons.speed),
  'HEART_RATE': ('Heart rate', 'bpm', Icons.favorite_border),
  'BLOOD_GLUCOSE': ('Blood glucose', 'mg/dL', Icons.bloodtype_outlined),
  'BODY_TEMPERATURE': ('Temperature', '°C', Icons.thermostat),
  'URINE_PH': ('Urine pH', 'pH', Icons.science_outlined),
  'SYMPTOM': ('Symptom', 'severity 1-5', Icons.healing),
  'MOOD': ('Mood', 'score 1-5', Icons.mood),
};

/// Health history + entry form. `readOnly` for doctors and caretakers (who can only view).
class HealthView extends StatefulWidget {
  final int patientId;
  final bool readOnly;
  const HealthView({super.key, required this.patientId, required this.readOnly});
  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  String? _filter;
  int _version = 0;

  void _refresh() {
    setState(() => _version++);
    if (!widget.readOnly) {
      try {
        context.read<PatientProvider>().load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.readOnly
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 84),
              child: FloatingActionButton.extended(
                backgroundColor: AppColors.lavenderDark,
                foregroundColor: Colors.white,
                onPressed: () => _addSheet(context, s),
                icon: const Icon(Icons.add),
                label: const Text('Add reading'),
              ),
            ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null))),
            for (final e in obsTypes.entries)
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value.$1), selected: _filter == e.key, onSelected: (_) => setState(() => _filter = e.key))),
          ]),
        ),
        Expanded(
          child: AsyncBody<List<Observation>>(
            key: ValueKey('$_filter-$_version'),
            load: () => s.health.list(widget.patientId, type: _filter),
            builder: (context, list, reload) {
              if (list.isEmpty) {
                return EmptyView(icon: Icons.monitor_heart_outlined, text: widget.readOnly ? 'No readings have been shared yet.' : 'No readings yet.\nTap "Add reading" to record your first one.');
              }
              return RefreshIndicator(
                onRefresh: reload,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 140), children: [
                  const Disclaimer('These are values entered by the patient, not clinical results. Only a doctor can interpret them.'),
                  for (final o in list)
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: AppColors.lavenderSoft, child: Icon(obsTypes[o.type]?.$3 ?? Icons.circle, color: AppColors.lavenderDark)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(o.type == 'SYMPTOM' ? (o.label ?? 'Symptom') : (obsTypes[o.type]?.$1 ?? titleCase(o.type)), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(fmtDateTime(o.observedAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            if (o.note != null) Text(o.note!, style: const TextStyle(fontSize: 13)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(o.valueText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          Text(o.unit, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ]),
                        if (!widget.readOnly)
                          IconButton(
                            tooltip: 'Delete entry',
                            icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                            onPressed: () async {
                              if (await confirm(context, 'Delete this entry?', 'This cannot be undone.', ok: 'Delete')) {
                                if (!context.mounted) return;
                                if (await guarded(context, () => s.health.delete(o.id))) _refresh();
                              }
                            },
                          ),
                      ]),
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _addSheet(BuildContext context, Services s) {
    String type = _filter ?? 'WEIGHT';
    final value = TextEditingController();
    final second = TextEditingController();
    final label = TextEditingController();
    final note = TextEditingController();
    int score = 3;
    showFormSheet(context, title: 'Add a reading', builder: (c) => StatefulBuilder(builder: (c, setState) {
          final scale = type == 'SYMPTOM' || type == 'MOOD';
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'What are you recording?'),
              items: [for (final e in obsTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value.$1))],
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 12),
            if (type == 'SYMPTOM') ...[
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Symptom (e.g. Back pain)')),
              const SizedBox(height: 12),
            ],
            if (scale) ...[
              Text(type == 'MOOD' ? 'Mood: $score / 5 (1 = low, 5 = great)' : 'Severity: $score / 5 (1 = mild, 5 = severe)'),
              Slider(value: score.toDouble(), min: 1, max: 5, divisions: 4, label: '$score', onChanged: (v) => setState(() => score = v.round())),
            ] else if (type == 'BLOOD_PRESSURE')
              Row(children: [
                Expanded(child: TextField(controller: value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Systolic (top)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: second, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diastolic (bottom)'))),
              ])
            else
              TextField(controller: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Value', suffixText: obsTypes[type]!.$2)),
            const SizedBox(height: 12),
            TextField(controller: note, maxLength: 500, decoration: const InputDecoration(labelText: 'Note (optional)')),
            const SizedBox(height: 4),
            const Text('This is your own record. The app does not interpret it or give medical advice.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                double? v = scale ? score.toDouble() : double.tryParse(value.text.trim());
                if (v == null) return showSnack(c, 'Please enter a number', error: true);
                double? sec;
                if (type == 'BLOOD_PRESSURE') {
                  sec = double.tryParse(second.text.trim());
                  if (sec == null) return showSnack(c, 'Please enter both values', error: true);
                }
                final ok = await guarded(c, () => s.health.record({
                      'type': type,
                      'value': v,
                      'secondaryValue': sec,
                      'label': type == 'SYMPTOM' ? label.text.trim() : null,
                      'note': note.text.trim().isEmpty ? null : note.text.trim(),
                      'observedAt': DateTime.now().toUtc().toIso8601String(),
                    }), success: 'Saved');
                if (ok) {
                  if (c.mounted) Navigator.pop(c);
                  _refresh();
                }
              },
              child: const Text('Save reading'),
            ),
          ]);
        }));
  }
}
