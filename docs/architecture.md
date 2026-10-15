# Architecture

```
Flutter app (Android)                         Spring Boot 3 (modular monolith)                 MySQL 8
┌──────────────────────────┐   HTTPS/JSON    ┌────────────────────────────────────┐  JPA   ┌─────────┐
│ screens → providers →    │ ──────────────► │ Filter: JwtAuthFilter              │ ─────► │ mamacare│
│ services → ApiClient(Dio)│   Bearer JWT    │ Controller → Service → Repository  │        │   DB    │
│ secure token storage     │ ◄────────────── │ PatientAccessService (authz)       │        └─────────┘
│ local notifications      │                 │ AuditService, GlobalExceptionHandler│       ./data/private-uploads (files)
└──────────────────────────┘                 └────────────────────────────────────┘
```
The app never talks to MySQL. Business rules, validation, authentication and authorization live in the backend.

## Backend packages (`com.mamacare`)
`auth` (register/login/JWT) · `user` · `patient` (profile + **PatientAccessService**) · `pregnancy` (progress maths, week catalogue)
· `doctor` (profile, verification, doctor↔patient links) · `caretaker` (consent + permissions) · `appointment` · `health`
· `medicalrecord` (metadata + private file storage) · `medication` (meds, reminders, intakes) · `admin` · `audit` · `assistant`
(rule-based info bot) · `config` · `common` · `exception`.
The suggested `notification` package was **not** created: reminders are local notifications on the device; no server push exists.

## Security model
* **Authentication**: BCrypt password hashes; HS256 JWT containing only `sub` (user id) and `ver` (token version).
  Role and status are re-read from the database on every request, so client-supplied or stale role claims are worthless.
* **Logout / revocation**: logout, password change and admin suspension increment `tokenVersion`, which invalidates all issued tokens.
* **Account states**: `ACTIVE`, `PENDING` (doctors until verified), `REJECTED`, `SUSPENDED`. PENDING/REJECTED users get a role that matches
  no business endpoint, so they can only reach `/api/auth/**` and `/api/doctors/me/verification`.
* **Authorization**: URL rules (`/api/admin/**` ⇒ ADMIN) + `@PreAuthorize` per endpoint + **resource checks** in
  `PatientAccessService` for every `/api/patients/{id}/…` call:
  patient = self only · doctor = only patients with an `ACCEPTED` link · caretaker = only `GRANTED` access and only ticked categories ·
  admin = **no** medical data. Unauthorized → uniform 403.
* **Privacy details**: caretaker access requests by e-mail return the same answer whether or not the patient exists (no user enumeration);
  login does a BCrypt comparison even for unknown e-mails; doctor directory hides e-mail/phone/license; medical files are stored under random
  names in a private directory and only served through an access-checked endpoint (type whitelist + magic-byte check, 10 MB limit).
* **Audit log** (own transaction): register, login/failed login, logout, link/access changes, verification decisions, status changes,
  appointment changes, record create/view/download/delete, medication changes, and every non-owner read of health data. No passwords, tokens or values are logged.
* **Errors**: one JSON shape (`ApiError`), no stack traces, no SQL messages.
* **Config**: secrets only from environment variables; startup fails without `JWT_SECRET` (≥32 chars).

## Frontend
`AuthGate` selects the screen from the server-confirmed user (splash → login → role shell). `ApiClient` adds the bearer token, maps errors to
`ApiException` (network / validation / 401) and signs the user out on an expired session. Token in `flutter_secure_storage`. Medication reminders
are scheduled with `flutter_local_notifications` and re-synced whenever medications change.
