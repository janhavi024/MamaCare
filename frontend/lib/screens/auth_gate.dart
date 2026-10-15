import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_shell.dart';
import 'auth/login_screen.dart';
import 'auth/pending_screen.dart';
import 'auth/splash_screen.dart';
import 'caretaker/caretaker_shell.dart';
import 'doctor/doctor_shell.dart';
import 'patient/patient_shell.dart';

/// Chooses the screen from the server-confirmed session: splash -> login -> role home. Role comes from the backend.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        final u = auth.user!;
        if (!u.isActive) return const PendingScreen();
        final key = ValueKey('${u.id}-${u.role}');
        switch (u.role) {
          case 'PATIENT':
            return PatientShell(key: key);
          case 'DOCTOR':
            return DoctorShell(key: key);
          case 'CARETAKER':
            return CaretakerShell(key: key);
          case 'ADMIN':
            return AdminShell(key: key);
        }
        return const LoginScreen();
    }
  }
}
