import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Read-only pregnancy progress for another person's patient (used by caretakers).
class ProgressCard extends StatelessWidget {
  final int patientId;
  const ProgressCard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) => AsyncBody<Progress>(
        load: () => context.read<Services>().patient.progress(patientId),
        builder: (context, p, reload) {
          if (!p.hasPregnancy) return const EmptyView(icon: Icons.pregnant_woman, text: 'No active pregnancy is recorded.');
          final w = p.weekInfo;
          return ListView(padding: const EdgeInsets.all(16), children: [
            AppCard(
              radius: 28,
              child: Column(children: [
                Text('Week ${p.currentWeek} of 40', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                Text('Trimester ${p.trimester} · ${p.remainingWeeks} weeks to go', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                WeekTrack(week: p.currentWeek),
                const SizedBox(height: 12),
                Text('Due ${fmtDate(p.dueDate!)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
            if (w != null) AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('About the size of a ${w.fruit.toLowerCase()} (${w.size})', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(w.description),
            ])),
          ]);
        },
      );
}
