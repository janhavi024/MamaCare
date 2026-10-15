import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/patient_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'pregnancy_sheet.dart';

/// Week-by-week timeline (weeks 4-40) with the current week highlighted.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  int? _selected;
  int _trimesterFilter = 0; // 0 = all
  late Future<List<WeekInfo>> _timeline;

  @override
  void initState() {
    super.initState();
    _timeline = context.read<Services>().patient.timeline();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PatientProvider>();
    final current = (p.progress?.hasPregnancy ?? false) ? p.progress!.currentWeek : null;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<WeekInfo>>(
        future: _timeline,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: () => setState(() => _timeline = context.read<Services>().patient.timeline()));
          final all = snap.data!;
          final weeks = _trimesterFilter == 0 ? all : all.where((w) => w.trimester == _trimesterFilter).toList();
          final sel = _selected ?? current ?? 4;
          final info = all.firstWhere((w) => w.week == sel.clamp(4, 40), orElse: () => all.first);
          return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
            const Text('Pregnancy Journey', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(children: [
              for (final t in [0, 1, 2, 3])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t == 0 ? 'All' : 'Trimester $t'),
                    selected: _trimesterFilter == t,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: _trimesterFilter == t ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _trimesterFilter = t),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weeks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final w = weeks[i];
                  final isSel = w.week == sel;
                  final isNow = w.week == current;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = w.week),
                    child: Container(
                      width: 58,
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.lavenderDark : Colors.white,
                        borderRadius: BorderRadius.circular(29),
                        border: isNow && !isSel ? Border.all(color: AppColors.lavenderDark, width: 2) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Wk', style: TextStyle(fontSize: 11, color: isSel ? Colors.white70 : AppColors.muted)),
                        Text('${w.week}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isSel ? Colors.white : AppColors.ink)),
                        if (isNow) Icon(Icons.circle, size: 6, color: isSel ? Colors.white : AppColors.lavenderDark),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              radius: 28,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconButton(tooltip: 'Previous week', onPressed: info.week > 4 ? () => setState(() => _selected = info.week - 1) : null, icon: const Icon(Icons.chevron_left)),
                  Expanded(child: Column(children: [
                    Text('Week ${info.week}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    Text('Trimester ${info.trimester}', style: const TextStyle(color: AppColors.muted)),
                  ])),
                  IconButton(tooltip: 'Next week', onPressed: info.week < 40 ? () => setState(() => _selected = info.week + 1) : null, icon: const Icon(Icons.chevron_right)),
                ]),
                const SizedBox(height: 8),
                Center(child: Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFFD9C7), AppColors.peach])),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.child_care, color: Colors.white, size: 44),
                    Text(info.size, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                )),
                const SizedBox(height: 14),
                Center(child: Text('About the size of a ${info.fruit.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                const SizedBox(height: 10),
                Text(info.description, style: const TextStyle(fontSize: 15, height: 1.4)),
                if (info.milestones.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Commonly scheduled around now', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  for (final m in info.milestones) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, size: 18, color: AppColors.lavenderDark), const SizedBox(width: 8), Expanded(child: Text(m))])),
                ],
              ]),
            ),
            if (current == null)
              AppCard(onTap: () => showPregnancySheet(context), child: const Row(children: [Icon(Icons.add_circle_outline, color: AppColors.lavenderDark), SizedBox(width: 12), Expanded(child: Text('Add your due date to highlight your current week'))]))
            else if (sel != current)
              TextButton.icon(onPressed: () => setState(() => _selected = current), icon: const Icon(Icons.my_location), label: const Text('Jump to my current week')),
            const Disclaimer('General information only; every pregnancy is different. Your doctor decides which checks are right for you. Sizes are approximate.'),
          ]);
        },
      ),
    );
  }
}
