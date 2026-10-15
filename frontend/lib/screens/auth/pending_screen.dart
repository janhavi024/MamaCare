import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Shown to accounts that cannot use the app yet: doctors awaiting verification, rejected doctors, approval-pending users.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user!;
    final rejected = u.status == 'REJECTED';
    final doctor = u.role == 'DOCTOR';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: rejected ? AppColors.danger.withValues(alpha: 0.12) : AppColors.lavenderSoft,
              child: Icon(rejected ? Icons.block : Icons.hourglass_top_rounded, size: 44, color: rejected ? AppColors.danger : AppColors.lavenderDark),
            ),
            const SizedBox(height: 24),
            Text(rejected ? 'Verification not approved' : 'Awaiting approval', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              rejected
                  ? (auth.verificationNotes ?? 'An administrator could not verify your details.')
                  : doctor
                      ? 'Thanks for registering, Dr ${u.fullName}. An administrator is reviewing your license details. You will get access as soon as you are verified.'
                      : 'An administrator needs to approve your account before you can continue.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Check status'),
              onPressed: () => guarded(context, () => context.read<AuthProvider>().refresh()),
            ),
            if (rejected && doctor) ...[
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => _resubmit(context), child: const Text('Update details and resubmit')),
            ],
            TextButton(onPressed: () => context.read<AuthProvider>().logout(), child: const Text('Sign out')),
          ]),
        ),
      ),
    );
  }

  void _resubmit(BuildContext context) {
    final license = TextEditingController();
    final notes = TextEditingController();
    showFormSheet(context, title: 'Resubmit for verification', builder: (c) => Column(children: [
          TextField(controller: license, decoration: const InputDecoration(labelText: 'Medical license number')),
          const SizedBox(height: 12),
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes for the reviewer (optional)')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final ok = await guarded(context, () async {
                await context.read<Services>().doctors.submitVerification(license.text.trim(), notes.text.trim().isEmpty ? null : notes.text.trim());
                await context.read<AuthProvider>().refresh();
              }, success: 'Submitted for review');
              if (ok && c.mounted) Navigator.pop(c);
            },
            child: const Text('Submit'),
          ),
        ]));
  }
}
