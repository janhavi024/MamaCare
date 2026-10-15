import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'doctors_screen.dart';
import 'pregnancy_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _version = 0;

  Future<Map<String, dynamic>> _load(Services s, int id) async {
    final profile = await s.patient.profile(id);
    final links = await s.doctors.links();
    final access = await s.caretakers.accessForPatient();
    return {'profile': profile, 'links': links, 'access': access};
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    final user = context.watch<AuthProvider>().user!;
    final pp = context.watch<PatientProvider>();
    return SafeArea(
      bottom: false,
      child: AsyncBody<Map<String, dynamic>>(
        key: ValueKey(_version),
        load: () => _load(s, user.id),
        builder: (context, data, reload) {
          final profile = data['profile'] as Map<String, dynamic>;
          final links = data['links'] as List<Map<String, dynamic>>;
          final access = data['access'] as List<Map<String, dynamic>>;
          final prog = pp.progress;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
            Row(children: [
              AvatarCircle(initials(user.fullName), radius: 34),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(user.email, style: const TextStyle(color: AppColors.muted)),
              ])),
              IconButton.filledTonal(tooltip: 'Edit profile', icon: const Icon(Icons.edit_outlined), onPressed: () => _editProfile(context, s, user, profile)),
            ]),
            const SectionTitle('Personal details'),
            AppCard(child: Column(children: [
              _row('Phone', user.phone),
              _row('Date of birth', profile['dateOfBirth']),
              _row('Blood group', profile['bloodGroup']),
              _row('Height', profile['heightCm'] == null ? null : '${profile['heightCm']} cm'),
              _row('Emergency contact', profile['emergencyContactName'] == null ? null : '${profile['emergencyContactName']} ${profile['emergencyContactPhone'] ?? ''}'),
            ])),
            const SectionTitle('Pregnancy'),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (prog == null || !prog.hasPregnancy)
                const Text('No pregnancy recorded yet.')
              else ...[
                Text('Week ${prog.currentWeek} · Trimester ${prog.trimester}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Due ${fmtDate(prog.dueDate!)}', style: const TextStyle(color: AppColors.muted)),
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                FilledButton.tonal(onPressed: () => showPregnancySheet(context, editing: prog?.hasPregnancy ?? false).then((_) => setState(() => _version++)), child: Text(prog?.hasPregnancy == true ? 'Update dates' : 'Add pregnancy')),
                if (prog?.hasPregnancy == true)
                  OutlinedButton(
                    onPressed: () async {
                      if (await confirm(context, 'Mark pregnancy as completed?', 'Your journey will be closed. You can add a new pregnancy afterwards.', ok: 'Mark completed')) {
                        if (!context.mounted) return;
                        if (await guarded(context, () => s.patient.completePregnancy())) {
                          await pp.load();
                          setState(() => _version++);
                        }
                      }
                    },
                    child: const Text('Mark completed'),
                  ),
              ]),
            ])),
            const SectionTitle('Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SwitchListTile(
                value: profile['remindersEnabled'] != false,
                title: const Text('Medication reminders'),
                subtitle: const Text('Local notifications on this device'),
                onChanged: (v) async {
                  if (await guarded(context, () => s.patient.updateProfile({
                        'dateOfBirth': profile['dateOfBirth'],
                        'bloodGroup': profile['bloodGroup'],
                        'heightCm': profile['heightCm'],
                        'emergencyContactName': profile['emergencyContactName'],
                        'emergencyContactPhone': profile['emergencyContactPhone'],
                        'remindersEnabled': v,
                      }))) {
                    await pp.load();
                    setState(() => _version++);
                  }
                },
              ),
            ),
            SectionTitle('My doctors', trailing: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsScreen())).then((_) => setState(() => _version++)), child: const Text('Find doctors'))),
            if (links.isEmpty) const AppCard(child: Text('You have not requested any doctor yet.', style: TextStyle(color: AppColors.muted))),
            for (final l in links)
              AppCard(
                child: Row(children: [
                  const Icon(Icons.medical_services_outlined, color: AppColors.lavenderDark),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Dr ${l['doctorName']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  StatusChip(l['status']),
                  if (l['status'] == 'ACCEPTED' || l['status'] == 'PENDING')
                    IconButton(
                      tooltip: l['status'] == 'ACCEPTED' ? 'Revoke access' : 'Cancel request',
                      icon: const Icon(Icons.link_off),
                      onPressed: () async {
                        if (await confirm(context, 'Remove access?', 'Dr ${l['doctorName']} will no longer see your information.', ok: 'Remove')) {
                          if (!context.mounted) return;
                          if (await guarded(context, () => s.doctors.decideLink(l['id'], 'REVOKED'), success: 'Access removed')) setState(() => _version++);
                        }
                      },
                    ),
                ]),
              ),
            const SectionTitle('Caretaker access'),
            const Text('Caretakers (e.g. your partner or a relative) only see what you allow here.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            if (access.isEmpty) const AppCard(child: Text('No caretaker has asked for access. Ask them to register as a caretaker and request access using your email.', style: TextStyle(color: AppColors.muted))),
            for (final a in access) _accessCard(context, s, a),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ]);
        },
      ),
    );
  }

  Widget _row(String label, Object? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Expanded(child: Text(value == null || '$value'.trim().isEmpty ? '—' : '$value', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _accessCard(BuildContext context, Services s, Map<String, dynamic> a) {
    final status = a['status'] as String;
    final perms = [
      if (a['canViewHealth'] == true) 'Health',
      if (a['canViewMedications'] == true) 'Medications',
      if (a['canViewAppointments'] == true) 'Appointments',
      if (a['canViewRecords'] == true) 'Records',
    ];
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${a['caretakerName']}\n${a['caretakerEmail']}', style: const TextStyle(fontWeight: FontWeight.w600))),
          StatusChip(status),
        ]),
        if (status == 'GRANTED') Text('Can see: pregnancy progress${perms.isEmpty ? '' : ', ${perms.join(', ')}'}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          if (status == 'PENDING' || status == 'GRANTED')
            FilledButton.tonal(onPressed: () => _permissions(context, s, a), child: Text(status == 'PENDING' ? 'Review request' : 'Change permissions')),
          if (status == 'PENDING')
            OutlinedButton(onPressed: () async { if (await guarded(context, () => s.caretakers.decide(a['id'], {'status': 'REJECTED'}))) setState(() => _version++); }, child: const Text('Decline')),
          if (status == 'GRANTED')
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () async {
                if (await confirm(context, 'Revoke access?', '${a['caretakerName']} will immediately lose access.', ok: 'Revoke')) {
                  if (!context.mounted) return;
                  if (await guarded(context, () => s.caretakers.decide(a['id'], {'status': 'REVOKED'}), success: 'Access revoked')) setState(() => _version++);
                }
              },
              child: const Text('Revoke'),
            ),
        ]),
      ]),
    );
  }

  void _permissions(BuildContext context, Services s, Map<String, dynamic> a) {
    var health = a['canViewHealth'] == true, meds = a['canViewMedications'] == true, appts = a['canViewAppointments'] == true, records = a['canViewRecords'] == true;
    showFormSheet(context, title: 'What can ${a['caretakerName']} see?', builder: (c) => StatefulBuilder(builder: (c, setState) {
          return Column(children: [
            const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle, color: AppColors.success), title: Text('Pregnancy progress'), subtitle: Text('Always included')),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Health readings'), value: health, onChanged: (v) => setState(() => health = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Medications'), value: meds, onChanged: (v) => setState(() => meds = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Appointments'), value: appts, onChanged: (v) => setState(() => appts = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Medical records'), value: records, onChanged: (v) => setState(() => records = v)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final ok = await guarded(c, () => s.caretakers.decide(a['id'], {'status': 'GRANTED', 'canViewHealth': health, 'canViewMedications': meds, 'canViewAppointments': appts, 'canViewRecords': records}), success: 'Access updated');
                if (ok) {
                  if (c.mounted) Navigator.pop(c);
                  this.setState(() => _version++);
                }
              },
              child: const Text('Save access'),
            ),
          ]);
        }));
  }

  void _editProfile(BuildContext context, Services s, AppUser user, Map<String, dynamic> p) {
    final name = TextEditingController(text: user.fullName);
    final phone = TextEditingController(text: user.phone ?? '');
    final blood = TextEditingController(text: p['bloodGroup'] ?? '');
    final height = TextEditingController(text: p['heightCm']?.toString() ?? '');
    final ecName = TextEditingController(text: p['emergencyContactName'] ?? '');
    final ecPhone = TextEditingController(text: p['emergencyContactPhone'] ?? '');
    DateTime? dob = p['dateOfBirth'] == null ? null : DateTime.parse(p['dateOfBirth']);
    String? nz(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    showFormSheet(context, title: 'Edit profile', builder: (c) => StatefulBuilder(builder: (c, setState) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.cake_outlined),
              label: Text(dob == null ? 'Date of birth' : fmtDate(dob!)),
              onPressed: () async {
                final d = await pickDate(c, initial: dob ?? DateTime(1995), first: DateTime(1940), last: DateTime.now());
                if (d != null) setState(() => dob = d);
              },
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: blood, decoration: const InputDecoration(labelText: 'Blood group', hintText: 'e.g. O+'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: ecName, decoration: const InputDecoration(labelText: 'Emergency contact name')),
            const SizedBox(height: 10),
            TextField(controller: ecPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Emergency contact phone')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return showSnack(c, 'Name is required', error: true);
                final ok = await guarded(c, () async {
                  await context.read<AuthProvider>().updateProfile(name.text.trim(), nz(phone));
                  await s.patient.updateProfile({
                    'dateOfBirth': dob == null ? null : isoDate(dob!),
                    'bloodGroup': nz(blood),
                    'heightCm': int.tryParse(height.text.trim()),
                    'emergencyContactName': nz(ecName),
                    'emergencyContactPhone': nz(ecPhone),
                    'remindersEnabled': p['remindersEnabled'] != false,
                  });
                }, success: 'Profile updated');
                if (ok) {
                  if (c.mounted) Navigator.pop(c);
                  this.setState(() => _version++);
                }
              },
              child: const Text('Save'),
            ),
          ]);
        }));
  }
}
