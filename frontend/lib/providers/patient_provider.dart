import 'package:flutter/foundation.dart';
import '../core/notification_service.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Dashboard data for the signed-in patient. Loaded in parallel; each section fails independently.
class PatientProvider extends ChangeNotifier {
  final Services s;
  final int patientId;
  PatientProvider(this.s, this.patientId);

  Progress? progress;
  List<Observation> latest = [];
  List<Dose> doses = [];
  List<Appointment> upcoming = [];
  bool loading = true;
  String? error;
  bool remindersEnabled = true;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        s.patient.progress(patientId),
        s.health.latest(patientId),
        s.medications.today(patientId),
        s.appointments.mine(),
        s.patient.profile(patientId),
        s.medications.list(patientId),
      ]);
      progress = results[0] as Progress;
      latest = results[1] as List<Observation>;
      doses = results[2] as List<Dose>;
      upcoming = (results[3] as List<Appointment>).where((a) => a.isUpcoming).take(3).toList();
      remindersEnabled = (results[4] as Map<String, dynamic>)['remindersEnabled'] != false;
      await NotificationService.syncReminders(results[5] as List<Medication>, enabled: remindersEnabled);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  /// Re-schedules local notifications after the medication list changed.
  Future<void> resyncReminders() async {
    final meds = await s.medications.list(patientId);
    await NotificationService.syncReminders(meds, enabled: remindersEnabled);
  }

  Future<void> toggleDose(Dose d) async {
    if (d.taken) {
      await s.medications.undo(d.reminderId);
    } else {
      await s.medications.complete(d.reminderId);
    }
    doses = await s.medications.today(patientId);
    notifyListeners();
  }
}
