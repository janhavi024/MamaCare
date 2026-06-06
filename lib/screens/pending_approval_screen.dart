import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/doctor_provider.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  final bool isDoctor;

  const PendingApprovalScreen({super.key, this.isDoctor = false});

  @override
  Widget build(BuildContext context) {
    final color =
        isDoctor ? const Color(0xFF185FA5) : const Color(0xFFE8785A);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 52,
                  color: color,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Account Pending Approval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isDoctor
                    ? 'Your doctor account is being reviewed by our admin team. '
                        'You will be notified once approved.\n\n'
                        'This usually takes 1–2 business days.'
                    : 'Your account is being reviewed by our admin team. '
                        'You will gain full access once approved.\n\n'
                        'This usually takes a short time.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF888780),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECE8E3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If you have any questions, please contact support.',
                        style: TextStyle(
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    if (isDoctor) {
                      Provider.of<DoctorProvider>(context, listen: false)
                          .clear();
                    } else {
                      Provider.of<UserProvider>(context, listen: false)
                          .setUser(null);
                    }
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
