import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'appointments_view.dart';

/// Directory of verified doctors. A patient can request a doctor's care (which lets that doctor view their data once accepted).
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});
  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      body: AsyncBody<(List<Doctor>, List<Map<String, dynamic>>)>(
        key: ValueKey(_version),
        load: () async => (await s.doctors.directory(), await s.doctors.links()),
        builder: (context, data, reload) {
          final docs = data.$1;
          final links = {for (final l in data.$2) l['doctorId'] as int: l};
          if (docs.isEmpty) return const EmptyView(icon: Icons.medical_services_outlined, text: 'No verified doctors are available yet.');
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Disclaimer('Requesting a doctor lets them view your pregnancy data, readings, medicines and records after they accept. You can revoke access at any time in your profile.'),
              for (final d in docs)
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      AvatarCircle(initials(d.fullName)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Dr ${d.fullName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${d.specialization} · ${d.qualification}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        if (d.hospital != null) Text(d.hospital!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ])),
                      if (links[d.id] != null) StatusChip(links[d.id]!['status']),
                    ]),
                    if (d.bio != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(d.bio!)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: [
                      if (links[d.id] == null || {'DECLINED', 'REVOKED'}.contains(links[d.id]!['status']))
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Request care'),
                          onPressed: () async {
                            if (await guarded(context, () => s.doctors.requestLink(d.id, null), success: 'Request sent to Dr ${d.fullName}')) setState(() => _version++);
                          },
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: const Text('Book'),
                        onPressed: () => showBookSheet(context, doctor: d),
                      ),
                    ]),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }
}
