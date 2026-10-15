# MamaCare 🤰 – Maternal Healthcare App

Flutter mobile app + Java Spring Boot REST backend + MySQL for pregnancy tracking, health monitoring, appointments, medication
reminders and medical records, for four roles: **patient, doctor, caretaker, administrator**.
Academic / portfolio project (originally a Flutter + Firebase prototype, re-architected to a REST backend).

> ⚠️ **Status:** the source was written and statically reviewed, but **it has not been compiled or run by the author of this delivery**
> (the authoring environment had no Flutter SDK, Maven or network). Follow the steps below; see [`docs/PROGRESS.md`](docs/PROGRESS.md) for exactly what is verified and what is not.
> MamaCare is **not** a medical device, is not certified as production-ready or legally compliant (HIPAA/GDPR/India DPDP…), and gives no medical advice.

## Features
* **Patient** – dashboard in the lavender "Pregnancy Monitor" style (week/month/trimester progress, baby-size card, health tiles, today's medicines,
  upcoming appointments), week-by-week journey (weeks 4-40), health monitoring (weight, BP, heart rate, glucose, temperature, urine pH, symptoms, mood),
  appointments (request/cancel), private medical records with file upload, medication reminders with local notifications, profile, doctors directory,
  caretaker consent management, rule-based health-information assistant.
* **Doctor** – verification by admin, accept/decline patients, view only linked patients' data, confirm due dates, prescribe medicines, add notes/records, manage appointment status.
* **Caretaker** – requests access by the mother's e-mail; sees only what she ticks (health / medications / appointments / records); can leave; she can revoke at any time.
* **Admin** – approve/reject doctors, search/suspend/activate users, stats, audit log. Admins can **not** read medical data.

## Tech stack
Flutter 3 · Dart · Material 3 · Provider · Dio · flutter_secure_storage · flutter_local_notifications · file_picker |
Java 17 · Spring Boot 3.3 (Web, Security, Data JPA/Hibernate, Validation) · JWT (jjwt) · Maven | MySQL 8 | JUnit 5 · Mockito · MockMvc + H2 for tests.

## Repository layout
```
MamaCare/
├─ backend/    Spring Boot app (com.mamacare.*), tests in src/test
├─ frontend/   Flutter app (lib/core, models, services, providers, widgets, screens)
├─ docs/       assessment, architecture, database-schema (ER diagram), api-documentation, legacy-firestore-review, PROGRESS, screenshots/
└─ README.md
```

## 1. Database
```sql
CREATE DATABASE mamacare CHARACTER SET utf8mb4;
CREATE USER 'mamacare'@'localhost' IDENTIFIED BY 'choose-a-strong-password';
GRANT ALL PRIVILEGES ON mamacare.* TO 'mamacare'@'localhost';
```
Tables are created automatically on first start (`ddl-auto=update`, dev only). See [`docs/database-schema.md`](docs/database-schema.md).

## 2. Backend  (JDK 17+, Maven 3.9+)
Secrets come from environment variables only (see `backend/.env.example`).
```bash
cd backend
# macOS / Linux
export DB_PASSWORD='choose-a-strong-password'
export JWT_SECRET="$(openssl rand -base64 48)"
export ADMIN_EMAIL='admin@example.com'          # creates the first admin if none exists
export ADMIN_PASSWORD='ChangeMe-Admin-123'
mvn spring-boot:run
```
```powershell
# Windows PowerShell
cd backend
$env:DB_PASSWORD="choose-a-strong-password"
$env:JWT_SECRET=[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
$env:ADMIN_EMAIL="admin@example.com"; $env:ADMIN_PASSWORD="ChangeMe-Admin-123"
mvn spring-boot:run
```
Optional: `DB_URL`, `DB_USERNAME`, `PORT`, `STORAGE_DIR` (private upload folder, default `./data/private-uploads`), `REQUIRE_PATIENT_APPROVAL=true`, `CORS_ALLOWED_ORIGINS`.
The API is on `http://localhost:8080`. Quick check: `curl -i http://localhost:8080/api/auth/me` → `401` (expected).
In IntelliJ/VS Code set the same variables in the run configuration.

## 3. Flutter app  (Flutter SDK matching `sdk: ^3.11.5`, Android Studio/emulator)
```bash
cd frontend
flutter pub get
flutter run                                                   # Android emulator → API at http://10.0.2.2:8080
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080   # physical phone: your PC's LAN IP (same Wi-Fi, firewall open)
```
* **Android emulator:** `localhost` would point at the emulator itself; the host machine is `10.0.2.2` (default in `lib/core/config.dart`).
* Debug builds allow cleartext HTTP (`android/app/src/debug/AndroidManifest.xml`). **Release builds must use HTTPS** – don't ship HTTP.
* If Gradle complains about the removed Google services plugin, run `flutter clean` first. If your Android SDK/NDK versions differ, adjust `android/app/build.gradle.kts`.
* `minSdk` is 23 (needed by flutter_secure_storage). Android 13+ asks for notification permission on first launch.

## 4. Try the whole flow
1. Register a **doctor** in the app → "Awaiting approval". Sign in as the **admin** (`ADMIN_EMAIL`) → *Doctor verification* → Approve.
2. Register a **patient** (set a due date) → dashboard shows progress. Add health readings, a medicine with reminder times, a record.
3. Patient → *Doctors* → *Request care*; doctor accepts under *Patient requests*; the doctor can now open the patient, confirm the due date, prescribe, add notes.
4. Patient → *Book* an appointment; doctor confirms it.
5. Register a **caretaker**, request access with the patient's e-mail; patient approves in *Profile → Caretaker access* choosing categories; revoke to test.

## 5. Tests
```bash
cd backend && mvn test           # unit + MockMvc integration tests on in-memory H2 (no MySQL needed)
cd frontend && flutter test      # model unit tests
flutter analyze                  # static analysis
```
Backend tests cover registration/login/BCrypt hashing, validation errors, token revocation, role escalation attempts, patient data ownership,
doctor link / caretaker consent / admin isolation, appointments (conflicts, transitions), health validation, pregnancy maths, medications/reminders,
medical-record upload & access, file-storage hardening, assistant safety. API usage: [`docs/api-documentation.md`](docs/api-documentation.md).

## Current limitations
* Not compiled/run by the author of this delivery (see PROGRESS). Expect small compile/dependency-version fixes on first build.
* No Firestore → MySQL data migration; no Flyway migrations (Hibernate `update` in dev); no refresh tokens (2-hour JWT, then sign in again); no login rate-limiting.
* Record attachments can be uploaded but **not opened inside the app** (download endpoint exists). Files are on local disk, unencrypted, no antivirus scan.
* No push notifications (FCM) – reminders are local only; times are tied to the device's current UTC offset.
* Assistant is rule-based (no LLM). No automatic charts; lists show the latest 100 items without infinite scroll.
* Appointment double-booking protection is application-level (no DB constraint). Unit tests of Flutter widgets/providers are minimal.
* Only Android was configured/tested conceptually; iOS/web folders are not included.

## Future improvements
Flyway migrations · refresh tokens + rate limiting · HTTPS/reverse proxy · object storage with encryption & virus scan · in-app document viewer · FCM push ·
charts for readings · LLM-backed assistant behind the same endpoint · CI (GitHub Actions) · OpenAPI/Swagger · Docker Compose.

## License / data
Demo project. Contains no real patient data. Do not store real medical information without a proper security and compliance review.
