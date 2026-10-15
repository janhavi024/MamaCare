import 'package:flutter_test/flutter_test.dart';
import 'package:mamacare/models/models.dart';

void main() {
  test('Progress.fromJson handles "no pregnancy"', () {
    final p = Progress.fromJson({'hasPregnancy': false});
    expect(p.hasPregnancy, false);
  });

  test('Observation formats blood pressure and decimals', () {
    final bp = Observation.fromJson({
      'id': 1, 'type': 'BLOOD_PRESSURE', 'value': 118.0, 'secondaryValue': 76.0, 'unit': 'mmHg',
      'observedAt': '2026-10-14T10:00:00Z',
    });
    expect(bp.valueText, '118/76');
    final w = Observation.fromJson({'id': 2, 'type': 'WEIGHT', 'value': 64.5, 'unit': 'kg', 'observedAt': '2026-10-14T10:00:00Z'});
    expect(w.valueText, '64.5');
  });

  test('Appointment upcoming logic', () {
    final future = DateTime.now().add(const Duration(days: 2)).toUtc().toIso8601String();
    final a = Appointment.fromJson({
      'id': 1, 'patientId': 1, 'patientName': 'P', 'doctorId': 2, 'doctorName': 'D', 'scheduledAt': future, 'status': 'CONFIRMED',
    });
    expect(a.isUpcoming, true);
    final cancelled = Appointment.fromJson({
      'id': 2, 'patientId': 1, 'patientName': 'P', 'doctorId': 2, 'doctorName': 'D', 'scheduledAt': future, 'status': 'CANCELLED',
    });
    expect(cancelled.isUpcoming, false);
  });
}
