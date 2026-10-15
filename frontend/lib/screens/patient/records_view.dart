import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

const _recordTypes = ['LAB_REPORT', 'ULTRASOUND', 'PRESCRIPTION', 'DOCTOR_NOTE', 'OTHER'];

IconData _recordIcon(String t) => switch (t) {
      'LAB_REPORT' => Icons.science_outlined,
      'ULTRASOUND' => Icons.image_outlined,
      'PRESCRIPTION' => Icons.receipt_long_outlined,
      'DOCTOR_NOTE' => Icons.edit_note,
      _ => Icons.description_outlined,
    };

/// Medical records for one patient. The server decides what is visible; this widget only renders what it is allowed to fetch.
class RecordsView extends StatefulWidget {
  final int patientId;
  final bool canWrite;
  const RecordsView({super.key, required this.patientId, required this.canWrite});
  @override
  State<RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<RecordsView> {
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.read<Services>();
    final me = context.read<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.canWrite
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.lavenderDark,
              foregroundColor: Colors.white,
              onPressed: () => _addSheet(context, s),
              icon: const Icon(Icons.upload_file),
              label: const Text('Add record'),
            )
          : null,
      body: AsyncBody<List<RecordItem>>(
        key: ValueKey(_version),
        load: () => s.records.list(widget.patientId),
        builder: (context, list, reload) {
          if (list.isEmpty) return const EmptyView(icon: Icons.folder_open, text: 'No medical records yet.');
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [
              const Disclaimer('Records are private. Only you, doctors you have accepted, and caretakers you explicitly allow can see them.'),
              for (final r in list)
                AppCard(
                  onTap: () => _detail(context, s, r, me),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: AppColors.lavenderSoft, child: Icon(_recordIcon(r.type), color: AppColors.lavenderDark)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${titleCase(r.type)} · ${fmtDate(r.recordDate)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text('Added by ${r.uploadedByName}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ])),
                    if (r.hasFile) const Icon(Icons.attach_file, color: AppColors.lavenderDark),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }

  void _detail(BuildContext context, Services s, RecordItem r, AppUser me) {
    final myOwn = me.id == widget.patientId;
    showFormSheet(context, title: r.title, builder: (c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${titleCase(r.type)} · ${fmtDate(r.recordDate)}', style: const TextStyle(color: AppColors.muted)),
          Text('Added by ${r.uploadedByName}', style: const TextStyle(color: AppColors.muted)),
          if (r.notes != null) ...[const SizedBox(height: 12), Text(r.notes!)],
          if (r.hasFile) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file),
              title: Text(r.fileName ?? 'Attachment'),
              subtitle: Text('${((r.sizeBytes ?? 0) / 1024).ceil()} KB · stored privately on the server'),
            ),
            const Text('Opening attachments inside the app is not implemented yet. The file is available through the authenticated API (GET /api/records/{id}/file).', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          if (widget.canWrite && (myOwn || r.uploadedByName == me.fullName)) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete record'),
              onPressed: () async {
                if (await confirm(c, 'Delete this record?', 'The record and its file will be permanently removed.', ok: 'Delete')) {
                  if (!c.mounted) return;
                  if (await guarded(c, () => s.records.delete(r.id), success: 'Deleted')) {
                    if (c.mounted) Navigator.pop(c);
                    setState(() => _version++);
                  }
                }
              },
            ),
          ],
        ]));
  }

  void _addSheet(BuildContext context, Services s) {
    final title = TextEditingController();
    final notes = TextEditingController();
    String type = 'LAB_REPORT';
    PlatformFile? file;
    bool busy = false;
    showFormSheet(context, title: 'Add a record', builder: (c) => StatefulBuilder(builder: (c, setState) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [for (final t in _recordTypes) DropdownMenuItem(value: t, child: Text(titleCase(t)))],
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(file == null ? 'Attach PDF / image (max 10 MB)' : file!.name),
              onPressed: () async {
                final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg']);
                if (res != null && res.files.single.path != null) setState(() => file = res.files.single);
              },
            ),
            const SizedBox(height: 16),
            BusyButton(
              label: 'Save record',
              busy: busy,
              onPressed: () async {
                if (title.text.trim().isEmpty) return showSnack(c, 'Please add a title', error: true);
                setState(() => busy = true);
                final ok = await guarded(c, () async {
                  final rec = await s.records.create(widget.patientId, {
                    'type': type,
                    'title': title.text.trim(),
                    'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
                    'recordDate': isoDate(DateTime.now()),
                  });
                  if (file != null) await s.records.upload(rec.id, file!.path!, file!.name);
                }, success: 'Record saved');
                if (c.mounted) setState(() => busy = false);
                if (ok) {
                  if (c.mounted) Navigator.pop(c);
                  this.setState(() => _version++);
                }
              },
            ),
          ]);
        }));
  }
}
