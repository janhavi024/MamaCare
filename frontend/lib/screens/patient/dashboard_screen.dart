import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/widgets.dart';
import 'appointments_view.dart';
import 'doctors_screen.dart';
import 'medications_view.dart';
import 'pregnancy_sheet.dart';
import 'records_view.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _unit = 'Weeks';

  // Pushed routes live above PatientShell, so hand them the provider explicitly.
  void _push(Widget page) {
    final provider = context.read<PatientProvider>();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: provider, child: page))).then((_) {
      if (mounted) provider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final p = context.watch<PatientProvider>();
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Row(children: [
              AvatarCircle(initials(user.fullName), radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting(), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  Text('Hello, ${firstName(user.fullName)}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ]),
              ),
              Badge(
                isLabelVisible: p.doses.any((d) => !d.taken),
                child: IconButton.filledTonal(
                  tooltip: 'Medication reminders',
                  style: IconButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => _push(Scaffold(appBar: AppBar(title: const Text('Medications')), body: MedicationsView(patientId: user.id, role: 'PATIENT'))),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (p.loading && p.progress == null)
              const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
            else if (p.error != null && p.progress == null)
              ErrorView(message: p.error!, onRetry: p.load)
            else ...[
              Row(children: [
                for (final u in ['Weeks', 'Months', 'Trimesters'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(u), selected: _unit == u, showCheckmark: false, labelStyle: TextStyle(color: _unit == u ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600), onSelected: (_) => setState(() => _unit = u)),
                  ),
              ]),
              const SizedBox(height: 14),
              _hero(p.progress!),
              const SectionTitle('Health overview'),
              _healthTiles(p.latest),
              const SectionTitle('Medications today'),
              _medsCard(p, user.id),
              SectionTitle('Upcoming appointments', trailing: TextButton(onPressed: () => _push(Scaffold(appBar: AppBar(title: const Text('Appointments')), body: const AppointmentsView(canBook: true))), child: const Text('See all'))),
              if (p.upcoming.isEmpty)
                const AppCard(child: Text('No upcoming appointments. Tap "See all" to book one.', style: TextStyle(color: AppColors.muted)))
              else
                for (final a in p.upcoming) _apptTile(a),
              const SectionTitle('Quick access'),
              _quickGrid(user.id),
              const SizedBox(height: 8),
              const Disclaimer('MamaCare helps you keep track of your pregnancy. It does not give medical advice. Always follow your doctor\'s guidance.'),
            ],
          ],
        ),
      ),
    );
  }

  String _heroLabel(Progress pr) {
    switch (_unit) {
      case 'Months':
        return 'Month ${(pr.completedWeeks * 7 / 30.44).floor() + 1} of 9';
      case 'Trimesters':
        return 'Trimester ${pr.trimester} of 3';
      default:
        return 'Week ${pr.currentWeek} of 40';
    }
  }

  Widget _hero(Progress pr) {
    if (!pr.hasPregnancy) {
      return AppCard(
        radius: 32,
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const CircleAvatar(radius: 40, backgroundColor: AppColors.lavenderSoft, child: Icon(Icons.pregnant_woman, size: 44, color: AppColors.lavenderDark)),
          const SizedBox(height: 14),
          const Text('Start your pregnancy journey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Add your due date to see your week-by-week progress.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => showPregnancySheet(context), child: const Text('Add due date')),
        ]),
      );
    }
    final w = pr.weekInfo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF3E8FF), Colors.white]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.lavenderDark.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text('Pregnancy Journey', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          InkWell(
            onTap: () => widget.onNavigate(1),
            borderRadius: BorderRadius.circular(24),
            child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle), child: const Icon(Icons.north_east, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 6),
        SizedBox(
          height: 250,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 168,
              height: 168,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFFD9C7), AppColors.peach])),
              child: const Icon(Icons.child_care_rounded, size: 96, color: Colors.white),
            ),
            Positioned(right: 0, top: 10, child: Transform.rotate(angle: 0.17, child: _glass('${pr.completedWeeks}', 'Completed\nWeek'))),
            Positioned(left: 0, bottom: 10, child: Transform.rotate(angle: -0.17, child: _glass(pr.remainingWeeks.toString().padLeft(2, '0'), 'Remaining\nWeek'))),
          ]),
        ),
        Text(_heroLabel(pr), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        if (w != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Your baby is about the size of a ${w.fruit.toLowerCase()} (${w.size})', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted))),
        const SizedBox(height: 16),
        WeekTrack(week: pr.currentWeek),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Due ${fmtDate(pr.dueDate!)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${pr.daysUntilDue} days to go', style: const TextStyle(color: AppColors.muted)),
        ]),
        if (pr.dueDateSource == 'DOCTOR_CONFIRMED') const Align(alignment: Alignment.centerLeft, child: Text('Due date confirmed by your doctor', style: TextStyle(fontSize: 12, color: AppColors.success))),
      ]),
    );
  }

  Widget _glass(String big, String small) => Container(
        width: 118,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: AppColors.lavenderDark.withValues(alpha: 0.15), blurRadius: 14)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(big, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          Text(small, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
      );

  Observation? _last(List<Observation> l, String type) {
    for (final o in l) {
      if (o.type == type) return o;
    }
    return null;
  }

  Widget _tile(String title, IconData icon, Observation? o, {bool purple = false, String emptyHint = 'Add reading'}) {
    final fg = purple ? Colors.white : AppColors.ink;
    return Expanded(
      child: Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: purple ? AppColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(26),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => widget.onNavigate(2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: purple ? Colors.white24 : AppColors.lavenderSoft, child: Icon(icon, size: 18, color: purple ? Colors.white : AppColors.lavenderDark)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                ]),
                const Spacer(),
                if (o == null)
                  Text(emptyHint, style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 14))
                else
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(o.valueText, style: TextStyle(color: fg, fontSize: 34, fontWeight: FontWeight.w600)))),
                    const SizedBox(width: 4),
                    Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(o.unit.split(' ').first, style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 12))),
                  ]),
                if (o != null) Text(fmtDate(o.observedAt), style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 11)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _healthTiles(List<Observation> l) => Column(children: [
        Row(children: [
          _tile('Heart Rate', Icons.favorite_border, _last(l, 'HEART_RATE')),
          const SizedBox(width: 12),
          _tile('Blood Pressure', Icons.speed, _last(l, 'BLOOD_PRESSURE'), purple: true),
        ]),
        Row(children: [
          _tile('Weight', Icons.monitor_weight_outlined, _last(l, 'WEIGHT'), purple: true),
          const SizedBox(width: 12),
          _tile('Latest symptom', Icons.healing, _last(l, 'SYMPTOM'), emptyHint: 'None logged'),
        ]),
        const Text('Values are entered by you. They are not interpreted or diagnosed by the app.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);

  Widget _medsCard(PatientProvider p, int userId) {
    final taken = p.doses.where((d) => d.taken).length;
    return AppCard(
      onTap: () => _push(Scaffold(appBar: AppBar(title: const Text('Medications')), body: MedicationsView(patientId: userId, role: 'PATIENT'))),
      child: p.doses.isEmpty
          ? const Row(children: [Icon(Icons.medication_outlined, color: AppColors.lavenderDark), SizedBox(width: 12), Expanded(child: Text('No reminders for today. Tap to add a medicine you have been prescribed.', style: TextStyle(color: AppColors.muted)))])
          : Column(children: [
              Row(children: [
                Expanded(child: Text('$taken of ${p.doses.length} doses taken', style: const TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 60, child: LinearProgressIndicator(value: taken / p.doses.length, borderRadius: BorderRadius.circular(8), minHeight: 8)),
              ]),
              const SizedBox(height: 8),
              for (final d in p.doses.take(3))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: d.taken,
                  onChanged: (_) => guarded(context, () => p.toggleDose(d)),
                  title: Text('${d.medicationName} · ${d.dosage}'),
                  subtitle: Text(fmtTimeOfDay(d.timeOfDay)),
                ),
            ]),
    );
  }

  Widget _apptTile(Appointment a) => AppCard(
        child: Row(children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text(a.scheduledAt.day.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][a.scheduledAt.month - 1], style: const TextStyle(fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr ${a.doctorName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(fmtDateTime(a.scheduledAt), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ])),
          StatusChip(a.status),
        ]),
      );

  Widget _quickGrid(int userId) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.calendar_month_rounded, 'Appointments', () => _push(Scaffold(appBar: AppBar(title: const Text('Appointments')), body: const AppointmentsView(canBook: true)))),
      (Icons.medication_rounded, 'Medications', () => _push(Scaffold(appBar: AppBar(title: const Text('Medications')), body: MedicationsView(patientId: userId, role: 'PATIENT')))),
      (Icons.folder_copy_rounded, 'Records', () => _push(Scaffold(appBar: AppBar(title: const Text('Medical records')), body: RecordsView(patientId: userId, canWrite: true)))),
      (Icons.medical_services_rounded, 'Doctors', () => _push(const DoctorsScreen())),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        for (final i in items)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: i.$3,
            child: Column(children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Icon(i.$1, color: AppColors.lavenderDark)),
              const SizedBox(height: 6),
              Text(i.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ]),
          ),
      ],
    );
  }
}
