/// Typed models for the patient-facing data. Staff/admin lists use plain JSON maps (see services).

DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);
double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

class AppUser {
  final int id;
  final String fullName, email, role, status;
  final String? phone;
  AppUser({required this.id, required this.fullName, required this.email, required this.role, required this.status, this.phone});
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
      id: j['id'], fullName: j['fullName'], email: j['email'], role: j['role'], status: j['status'], phone: j['phone']);
  bool get isActive => status == 'ACTIVE';
}

class WeekInfo {
  final int week, trimester;
  final String fruit, size, description;
  final List<String> milestones;
  WeekInfo({required this.week, required this.trimester, required this.fruit, required this.size, required this.description, required this.milestones});
  factory WeekInfo.fromJson(Map<String, dynamic> j) => WeekInfo(
      week: j['week'], trimester: j['trimester'], fruit: j['fruit'], size: j['size'], description: j['description'],
      milestones: (j['milestones'] as List).map((e) => e.toString()).toList());
}

class Progress {
  final bool hasPregnancy;
  final DateTime? dueDate;
  final int completedWeeks, daysIntoWeek, currentWeek, remainingWeeks, daysUntilDue, trimester;
  final double percent;
  final WeekInfo? weekInfo;
  final String? dueDateSource;
  Progress({required this.hasPregnancy, this.dueDate, this.completedWeeks = 0, this.daysIntoWeek = 0, this.currentWeek = 0,
    this.remainingWeeks = 0, this.daysUntilDue = 0, this.trimester = 1, this.percent = 0, this.weekInfo, this.dueDateSource});
  factory Progress.fromJson(Map<String, dynamic> j) {
    if (j['hasPregnancy'] != true) return Progress(hasPregnancy: false);
    return Progress(
      hasPregnancy: true,
      dueDate: _dt(j['dueDate']),
      completedWeeks: j['completedWeeks'],
      daysIntoWeek: j['daysIntoWeek'],
      currentWeek: j['currentWeek'],
      remainingWeeks: j['remainingWeeks'],
      daysUntilDue: j['daysUntilDue'],
      trimester: j['trimester'],
      percent: _d(j['percentComplete']) ?? 0,
      weekInfo: j['weekInfo'] == null ? null : WeekInfo.fromJson(j['weekInfo']),
      dueDateSource: j['dueDateSource'],
    );
  }
}

class Observation {
  final int id;
  final String type, unit;
  final double value;
  final double? secondary;
  final String? label, note;
  final DateTime observedAt;
  Observation({required this.id, required this.type, required this.value, this.secondary, required this.unit, this.label, this.note, required this.observedAt});
  factory Observation.fromJson(Map<String, dynamic> j) => Observation(
      id: j['id'], type: j['type'], value: _d(j['value'])!, secondary: _d(j['secondaryValue']), unit: j['unit'],
      label: j['label'], note: j['note'], observedAt: _dt(j['observedAt'])!.toLocal());

  static String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// e.g. "118/76", "85", "5.2"
  String get valueText => secondary != null ? '${_n(value)}/${_n(secondary!)}' : _n(value);
}

class Appointment {
  final int id, patientId, doctorId;
  final String patientName, doctorName, status;
  final DateTime scheduledAt;
  final String? reason, doctorNote;
  Appointment({required this.id, required this.patientId, required this.patientName, required this.doctorId, required this.doctorName,
    required this.scheduledAt, this.reason, required this.status, this.doctorNote});
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
      id: j['id'], patientId: j['patientId'], patientName: j['patientName'], doctorId: j['doctorId'], doctorName: j['doctorName'],
      scheduledAt: _dt(j['scheduledAt'])!.toLocal(), reason: j['reason'], status: j['status'], doctorNote: j['doctorNote']);
  bool get isActive => status == 'REQUESTED' || status == 'CONFIRMED';
  bool get isUpcoming => isActive && scheduledAt.isAfter(DateTime.now());
}

class Reminder {
  final int id, medicationId;
  final String timeOfDay;
  final bool enabled;
  Reminder({required this.id, required this.medicationId, required this.timeOfDay, required this.enabled});
  factory Reminder.fromJson(Map<String, dynamic> j) =>
      Reminder(id: j['id'], medicationId: j['medicationId'], timeOfDay: j['timeOfDay'], enabled: j['enabled']);
}

class Medication {
  final int id;
  final String name, dosage, frequency;
  final String? instructions, prescribedByName;
  final int? prescribedById;
  final bool active;
  final List<Reminder> reminders;
  Medication({required this.id, required this.name, required this.dosage, required this.frequency, this.instructions,
    this.prescribedById, this.prescribedByName, required this.active, required this.reminders});
  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
      id: j['id'], name: j['name'], dosage: j['dosage'], frequency: j['frequency'], instructions: j['instructions'],
      prescribedById: j['prescribedById'], prescribedByName: j['prescribedByName'], active: j['active'],
      reminders: (j['reminders'] as List).map((e) => Reminder.fromJson(e)).toList());
  bool get byDoctor => prescribedById != null;
}

class Dose {
  final int reminderId, medicationId;
  final String medicationName, dosage, timeOfDay;
  final bool taken;
  Dose({required this.reminderId, required this.medicationId, required this.medicationName, required this.dosage, required this.timeOfDay, required this.taken});
  factory Dose.fromJson(Map<String, dynamic> j) => Dose(
      reminderId: j['reminderId'], medicationId: j['medicationId'], medicationName: j['medicationName'], dosage: j['dosage'],
      timeOfDay: j['timeOfDay'], taken: j['taken']);
}

class RecordItem {
  final int id;
  final String type, title, uploadedByName;
  final String? notes, fileName;
  final DateTime recordDate;
  final int? sizeBytes;
  final bool hasFile;
  RecordItem({required this.id, required this.type, required this.title, required this.uploadedByName, this.notes, this.fileName,
    required this.recordDate, this.sizeBytes, required this.hasFile});
  factory RecordItem.fromJson(Map<String, dynamic> j) => RecordItem(
      id: j['id'], type: j['type'], title: j['title'], uploadedByName: j['uploadedByName'], notes: j['notes'], fileName: j['fileName'],
      recordDate: DateTime.parse(j['recordDate']), sizeBytes: j['sizeBytes'], hasFile: j['hasFile']);
}

class Doctor {
  final int id;
  final String fullName, specialization, qualification;
  final String? hospital, bio;
  final int? years;
  Doctor({required this.id, required this.fullName, required this.specialization, required this.qualification, this.hospital, this.bio, this.years});
  factory Doctor.fromJson(Map<String, dynamic> j) => Doctor(
      id: j['id'], fullName: j['fullName'], specialization: j['specialization'], qualification: j['qualification'],
      hospital: j['hospital'], bio: j['bio'], years: j['yearsOfExperience']);
}

List<T> pageItems<T>(dynamic json, T Function(Map<String, dynamic>) f) =>
    (json['content'] as List).map((e) => f(e as Map<String, dynamic>)).toList();
