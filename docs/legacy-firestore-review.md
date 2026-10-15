# Review of the original `firestore.rules`

Issues found in the original Firebase setup (now removed):

1. **Committed `google-services.json`** containing an API key (public-by-design in Firebase, but it should not live in Git and must be restricted/rotated).
2. **Any signed-in user could read every doctor profile** (`doctors`: `allow read: if isSignedIn()`), including license/contact fields.
3. **Unrestricted `create` on `doctor_requests`, `appointments`, `reports`, `doctor_medications`** (`allow create: if isSignedIn()`):
   any user could create records for *any* `patientId`/`doctorId`, including doctor-authored reports/prescriptions for other patients.
4. **Doctor access not tied to a relationship**: any *approved doctor* could read **every** patient's profile, medications, mood entries and tests.
   Access should require an accepted doctor-patient link.
5. **Patients could write their own `users` document** (only `approvalStatus` was protected) with no field-level validation.
6. **Caretaker access is decided by `linkedPatientId` stored in the caretaker's own, self-writable document** – a caretaker could set it to any patient id and read that patient's data (no patient consent). The rules also let a caretaker read the patient's `users`, medications and tests but no health-scope limits exist.
7. **Admin identified by existence of `/admins/{uid}`** and admins could read all patient health data (no least-privilege).
8. **Appointment/report deletion by doctors** possible without audit; no immutable history.
9. No validation of field types/ranges in rules (e.g. blood-pressure values, dates).

These are addressed in the new design by server-side authorization (`PatientAccessService`), consent-based caretaker access, accepted-link doctor access,
audit logging and an admin role with no medical-data access. If you keep the old Firebase project, **rotate its API key, deploy stricter rules or shut it down**.
