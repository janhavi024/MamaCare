import '../core/api_client.dart';
import '../core/format.dart';
import '../models/models.dart';

typedef Json = Map<String, dynamic>;

List<Json> _list(dynamic j) => (j as List).map((e) => e as Json).toList();
List<Json> _content(dynamic j) => _list(j['content']);

class AuthService {
  final ApiClient api;
  AuthService(this.api);
  Future<Json> login(String email, String password) async => await api.post('/api/auth/login', {'email': email, 'password': password});
  Future<Json> register(Json body) async => await api.post('/api/auth/register', body);
  Future<Json> me() async => await api.get('/api/auth/me');
  Future<void> updateMe(String fullName, String? phone) => api.put('/api/auth/me', {'fullName': fullName, 'phone': phone});
  Future<void> logout() => api.post('/api/auth/logout');
  Future<Json> changePassword(String current, String next) async =>
      await api.post('/api/auth/change-password', {'currentPassword': current, 'newPassword': next});
}

class PatientService {
  final ApiClient api;
  PatientService(this.api);
  Future<Json> profile(int id) async => await api.get('/api/patients/$id/profile');
  Future<Json> updateProfile(Json body) async => await api.put('/api/patients/me/profile', body);
  Future<Progress> progress(int id) async => Progress.fromJson(await api.get('/api/patients/$id/pregnancy/progress'));
  Future<Json> pregnancy(int id) async => await api.get('/api/patients/$id/pregnancy');
  Future<void> createPregnancy(Json body) => api.post('/api/patients/me/pregnancy', body);
  Future<void> updatePregnancy(Json body) => api.put('/api/patients/me/pregnancy', body);
  Future<void> completePregnancy() => api.post('/api/patients/me/pregnancy/complete');
  Future<List<WeekInfo>> timeline() async => _list(await api.get('/api/pregnancy/timeline')).map(WeekInfo.fromJson).toList();
}

class HealthService {
  final ApiClient api;
  HealthService(this.api);
  Future<void> record(Json body) => api.post('/api/patients/me/health-observations', body);
  Future<List<Observation>> list(int patientId, {String? type}) async => pageItems(
      await api.get('/api/patients/$patientId/health-observations', query: {'type': type, 'size': 100}), Observation.fromJson);
  Future<List<Observation>> latest(int patientId) async =>
      _list(await api.get('/api/patients/$patientId/health-observations/latest')).map(Observation.fromJson).toList();
  Future<void> delete(int id) => api.delete('/api/patients/me/health-observations/$id');
}

class AppointmentService {
  final ApiClient api;
  AppointmentService(this.api);
  Future<List<Appointment>> mine({String? status}) async =>
      pageItems(await api.get('/api/appointments', query: {'status': status, 'size': 100}), Appointment.fromJson);
  Future<List<Appointment>> forPatient(int id) async =>
      pageItems(await api.get('/api/patients/$id/appointments', query: {'size': 100}), Appointment.fromJson);
  Future<void> book({int? doctorId, int? patientId, required DateTime at, String? reason}) => api.post('/api/appointments', {
        if (doctorId != null) 'doctorId': doctorId,
        if (patientId != null) 'patientId': patientId,
        'scheduledAt': at.toUtc().toIso8601String(),
        'reason': (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
      });
  Future<void> setStatus(int id, String status, {String? note}) => api.patch('/api/appointments/$id/status', {'status': status, 'note': note});
}

class RecordService {
  final ApiClient api;
  RecordService(this.api);
  Future<List<RecordItem>> list(int patientId) async => pageItems(await api.get('/api/patients/$patientId/records', query: {'size': 100}), RecordItem.fromJson);
  Future<RecordItem> create(int patientId, Json body) async => RecordItem.fromJson(await api.post('/api/patients/$patientId/records', body));
  Future<void> upload(int recordId, String path, String name) => api.upload('/api/records/$recordId/file', path, name);
  Future<void> delete(int id) => api.delete('/api/records/$id');
}

class MedicationService {
  final ApiClient api;
  MedicationService(this.api);
  Future<List<Medication>> list(int patientId) async => _list(await api.get('/api/patients/$patientId/medications')).map(Medication.fromJson).toList();
  Future<void> create(int patientId, Json body) => api.post('/api/patients/$patientId/medications', body);
  Future<void> archive(int id) => api.delete('/api/medications/$id');
  Future<void> addReminder(int medId, String hhmm) => api.post('/api/medications/$medId/reminders', {'timeOfDay': hhmm});
  Future<void> toggleReminder(int id, bool enabled) => api.patch('/api/reminders/$id', {'enabled': enabled});
  Future<void> deleteReminder(int id) => api.delete('/api/reminders/$id');
  Future<List<Dose>> today(int patientId) async =>
      _list(await api.get('/api/patients/$patientId/medications/today', query: {'date': isoDate(DateTime.now())})).map(Dose.fromJson).toList();
  Future<void> complete(int reminderId) => api.post('/api/reminders/$reminderId/complete', {'date': isoDate(DateTime.now())});
  Future<void> undo(int reminderId) => api.delete('/api/reminders/$reminderId/complete', query: {'date': isoDate(DateTime.now())});
}

class DoctorService {
  final ApiClient api;
  DoctorService(this.api);
  Future<List<Doctor>> directory({String? q}) async => pageItems(await api.get('/api/doctors', query: {'q': q, 'size': 50}), Doctor.fromJson);
  Future<Json> me() async => await api.get('/api/doctors/me');
  Future<void> submitVerification(String license, String? notes) => api.post('/api/doctors/me/verification', {'licenseNumber': license, 'notes': notes});
  Future<List<Json>> myPatients() async => _content(await api.get('/api/doctors/me/patients', query: {'size': 100}));
  Future<List<Json>> links({String? status}) async => _content(await api.get('/api/care-links', query: {'status': status, 'size': 100}));
  Future<void> requestLink(int doctorId, String? message) => api.post('/api/care-links', {'doctorId': doctorId, 'message': message});
  Future<void> decideLink(int id, String status) => api.patch('/api/care-links/$id', {'status': status});
  Future<void> confirmDueDate(int patientId, DateTime due) => api.put('/api/patients/$patientId/pregnancy/due-date', {'dueDate': isoDate(due)});
}

class CaretakerService {
  final ApiClient api;
  CaretakerService(this.api);
  Future<String> request(String patientEmail) async => (await api.post('/api/caretaker/requests', {'patientEmail': patientEmail}))['message'];
  Future<List<Json>> myPatients() async => _list(await api.get('/api/caretaker/patients'));
  Future<void> leave(int accessId) => api.delete('/api/caretaker/access/$accessId');
  Future<List<Json>> accessForPatient() async => _list(await api.get('/api/patients/me/caretaker-access'));
  Future<void> decide(int id, Json body) => api.patch('/api/caretaker-access/$id', body);
}

class AdminService {
  final ApiClient api;
  AdminService(this.api);
  Future<Json> stats() async => await api.get('/api/admin/stats');
  Future<List<Json>> users({String? role, String? status, String? q}) async =>
      _content(await api.get('/api/admin/users', query: {'role': role, 'status': status, 'q': q, 'size': 100, 'sort': 'createdAt,desc'}));
  Future<void> setStatus(int id, String status) => api.patch('/api/admin/users/$id/status', {'status': status});
  Future<List<Json>> verifications({String? status}) async => _content(await api.get('/api/admin/doctor-verifications', query: {'status': status, 'size': 100}));
  Future<void> decide(int id, String decision, String? notes) => api.patch('/api/admin/doctor-verifications/$id', {'decision': decision, 'notes': notes});
  Future<List<Json>> audit() async => _content(await api.get('/api/admin/audit-logs', query: {'size': 100}));
}

class AssistantService {
  final ApiClient api;
  AssistantService(this.api);
  Future<Json> ask(String q) async => await api.post('/api/assistant/ask', {'question': q});
}

/// One object that wires every service to the shared ApiClient. Provided at the app root.
class Services {
  final ApiClient api;
  late final auth = AuthService(api);
  late final patient = PatientService(api);
  late final health = HealthService(api);
  late final appointments = AppointmentService(api);
  late final records = RecordService(api);
  late final medications = MedicationService(api);
  late final doctors = DoctorService(api);
  late final caretakers = CaretakerService(api);
  late final admin = AdminService(api);
  late final assistant = AssistantService(api);
  Services(this.api);
}
