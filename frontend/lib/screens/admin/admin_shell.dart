import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const titles = ['Overview', 'Doctor verification', 'Users', 'Audit log'];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(titles[_index]), actions: [
        IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: () => context.read<AuthProvider>().logout()),
      ]),
      body: IndexedStack(index: _index, children: [
        _Overview(key: ValueKey('o$_index')),
        _Verifications(key: ValueKey('v$_index')),
        _Users(key: ValueKey('u$_index')),
        _Audit(key: ValueKey('a$_index')),
      ]),
      bottomNavigationBar: PillNavBar(
        index: _index,
        icons: const [Icons.dashboard_rounded, Icons.verified_user_rounded, Icons.people_alt_rounded, Icons.history_rounded],
        labels: titles,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({super.key});
  @override
  Widget build(BuildContext context) => AsyncBody<Map<String, dynamic>>(
        load: () => context.read<Services>().admin.stats(),
        builder: (context, st, reload) {
          Widget tile(String label, Object v, IconData icon, {bool hot = false}) => AppCard(
                color: hot ? AppColors.lavender : null,
                child: Row(children: [
                  Icon(icon, color: hot ? Colors.white : AppColors.lavenderDark, size: 30),
                  const SizedBox(width: 14),
                  Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: hot ? Colors.white : AppColors.ink))),
                  Text('$v', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: hot ? Colors.white : AppColors.ink)),
                ]),
              );
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
              tile('Pending doctor verifications', st['pendingDoctorVerifications'], Icons.pending_actions, hot: (st['pendingDoctorVerifications'] as int) > 0),
              tile('Accounts awaiting approval', st['pendingAccounts'], Icons.hourglass_top),
              tile('Patients', st['patients'], Icons.pregnant_woman),
              tile('Doctors', st['doctors'], Icons.medical_services_outlined),
              tile('Caretakers', st['caretakers'], Icons.family_restroom),
              const Disclaimer('Administrators manage accounts only. Medical data of patients is not accessible to administrators.'),
            ]),
          );
        },
      );
}

class _Verifications extends StatefulWidget {
  const _Verifications({super.key});
  @override
  State<_Verifications> createState() => _VerificationsState();
}

class _VerificationsState extends State<_Verifications> {
  String _status = 'PENDING';
  int _v = 0;

  void _decide(Map<String, dynamic> item, String decision) {
    final notes = TextEditingController();
    final s = context.read<Services>();
    showFormSheet(context, title: decision == 'APPROVED' ? 'Approve Dr ${item['doctorName']}?' : 'Reject Dr ${item['doctorName']}?', builder: (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('License: ${item['licenseNumber'] ?? '—'}'),
          const SizedBox(height: 12),
          TextField(controller: notes, maxLines: 3, maxLength: 500, decoration: InputDecoration(labelText: decision == 'APPROVED' ? 'Notes (optional)' : 'Reason (shown to the doctor)')),
          const SizedBox(height: 8),
          FilledButton(
            style: decision == 'REJECTED' ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
            onPressed: () async {
              final ok = await guarded(c, () => s.admin.decide(item['id'], decision, notes.text.trim().isEmpty ? null : notes.text.trim()), success: decision == 'APPROVED' ? 'Doctor approved' : 'Doctor rejected');
              if (ok) {
                if (c.mounted) Navigator.pop(c);
                setState(() => _v++);
              }
            },
            child: Text(decision == 'APPROVED' ? 'Approve' : 'Reject'),
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'PENDING', label: Text('Pending')), ButtonSegment(value: 'APPROVED', label: Text('Approved')), ButtonSegment(value: 'REJECTED', label: Text('Rejected'))],
          selected: {_status},
          onSelectionChanged: (v) => setState(() => _status = v.first),
        ),
      ),
      Expanded(
        child: AsyncBody<List<Map<String, dynamic>>>(
          key: ValueKey('$_status$_v'),
          load: () => s.admin.verifications(status: _status),
          builder: (context, list, reload) => list.isEmpty
              ? EmptyView(icon: Icons.verified_outlined, text: 'No ${_status.toLowerCase()} requests.')
              : RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
                    for (final d in list)
                      AppCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text('Dr ${d['doctorName']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                            StatusChip(d['status']),
                          ]),
                          Text(d['doctorEmail'], style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('${d['specialization'] ?? ''} · ${d['qualification'] ?? ''}'),
                          if (d['hospital'] != null) Text(d['hospital']),
                          Text('License: ${d['licenseNumber'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (d['submittedNotes'] != null) Text('Notes: ${d['submittedNotes']}'),
                          if (d['reviewNotes'] != null) Text('Review: ${d['reviewNotes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          if (d['status'] != 'APPROVED') ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: FilledButton(onPressed: () => _decide(d, 'APPROVED'), child: const Text('Approve'))),
                              const SizedBox(width: 10),
                              if (d['status'] == 'PENDING') Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), onPressed: () => _decide(d, 'REJECTED'), child: const Text('Reject'))),
                            ]),
                          ],
                        ]),
                      ),
                  ]),
                ),
        ),
      ),
    ]);
  }
}

class _Users extends StatefulWidget {
  const _Users({super.key});
  @override
  State<_Users> createState() => _UsersState();
}

class _UsersState extends State<_Users> {
  String? _role;
  String? _status;
  String _q = '';
  int _v = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    final me = context.read<AuthProvider>().user!;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: TextField(decoration: const InputDecoration(hintText: 'Search name or email', prefixIcon: Icon(Icons.search)), onSubmitted: (v) => setState(() { _q = v.trim(); _v++; })),
      ),
      SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), children: [
          for (final r in [null, 'PATIENT', 'DOCTOR', 'CARETAKER'])
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(r == null ? 'All roles' : titleCase(r)), selected: _role == r, onSelected: (_) => setState(() { _role = r; _v++; }))),
          for (final st in ['PENDING', 'ACTIVE', 'SUSPENDED'])
            Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(titleCase(st)), selected: _status == st, onSelected: (on) => setState(() { _status = on ? st : null; _v++; }))),
        ]),
      ),
      Expanded(
        child: AsyncBody<List<Map<String, dynamic>>>(
          key: ValueKey(_v),
          load: () => s.admin.users(role: _role, status: _status, q: _q.isEmpty ? null : _q),
          builder: (context, list, reload) => list.isEmpty
              ? const EmptyView(icon: Icons.people_outline, text: 'No users match.')
              : RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
                    for (final u in list)
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          AvatarCircle(initials(u['fullName']), radius: 22),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u['fullName'], style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${titleCase(u['role'])} · ${u['email']}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ])),
                          StatusChip(u['status']),
                          if (u['role'] != 'ADMIN' && u['id'] != me.id)
                            PopupMenuButton<String>(
                              tooltip: 'Change status',
                              onSelected: (st) async {
                                if (await guarded(context, () => s.admin.setStatus(u['id'], st), success: 'Status updated')) setState(() => _v++);
                              },
                              itemBuilder: (_) => [
                                if (u['status'] != 'ACTIVE') const PopupMenuItem(value: 'ACTIVE', child: Text('Activate')),
                                if (u['status'] != 'SUSPENDED') const PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend')),
                              ],
                            ),
                        ]),
                      ),
                  ]),
                ),
        ),
      ),
    ]);
  }
}

class _Audit extends StatelessWidget {
  const _Audit({super.key});
  @override
  Widget build(BuildContext context) => AsyncBody<List<Map<String, dynamic>>>(
        load: () => context.read<Services>().admin.audit(),
        builder: (context, list, reload) => list.isEmpty
            ? const EmptyView(icon: Icons.history, text: 'No audit events yet.')
            : RefreshIndicator(
                onRefresh: reload,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
                  for (final e in list)
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e['action'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Actor: ${e['actorId'] ?? 'anonymous'} · ${e['entityType'] ?? ''} ${e['entityId'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        Text(fmtDateTime(DateTime.parse(e['createdAt'])), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                ]),
              ),
      );
}
