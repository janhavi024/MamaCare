# Progress report, verification status and next steps

## What was actually verified (and what was not)
| Check | Result |
|---|---|
| Original project inspected (source, rules, config) | ✅ done |
| Backend Java: syntax parse with the JDK 21 compiler (`jdk.compiler` module) over `src/main` + `src/test` | ✅ **no syntax errors**; remaining javac errors were only "cannot find symbol / package does not exist" because Spring, Lombok, jjwt jars were unavailable offline |
| Backend: full compile, `mvn test`, startup against MySQL | ❌ **not run** (no Maven / network in the authoring sandbox) |
| Flutter: `flutter pub get`, `analyze`, `test`, build | ❌ **not run** (no Flutter/Dart SDK). Only a heuristic check (bracket balance, missing imports) was done |
| Test results | **None to report.** Tests were written but never executed. |

Please run: `cd backend && mvn test` then `mvn spring-boot:run`; `cd frontend && flutter pub get && flutter analyze && flutter test && flutter run`.
Likely first-run fixes: dependency version bumps, small Dart analyzer deprecations (`DropdownButtonFormField.value`), Gradle/AGP differences in the copied Android project, a test expectation off by one.

## Acceptance criteria
| # | Criterion | Status |
|---|---|---|
| 1 | Flutter app starts | ⏳ unverified |
| 2 | Backend starts | ⏳ unverified |
| 3 | MySQL stores data | ⏳ implemented (JPA/MySQL driver), unverified |
| 4 | Register/login via backend | ✅ implemented, ⏳ unverified at runtime |
| 5 | Server-side auth + roles | ✅ implemented, tested in code, ⏳ tests not executed |
| 6 | Dashboard resembles reference | ✅ implemented (no screenshots yet; baby 3D render replaced by a drawn placeholder) |
| 7 | Pregnancy progress record/retrieve | ✅ implemented |
| 8 | Health observations | ✅ implemented |
| 9 | Appointments end-to-end | ✅ implemented (patient request → doctor confirm / cancel / complete) |
| 10 | Medical-record access restricted | ✅ implemented; **in-app file opening missing** |
| 11 | Medication reminders | ✅ implemented (server schedule + local notifications; not push) |
| 12 | Doctor/caretaker/admin workflows | ✅ migrated with changes (see assessment) |
| 13 | Backend tests | ✅ written (59 tests) · ⏳ never executed |
| 14 | README explains running | ✅ |
| 15 | No credentials/private data committed | ✅ (`google-services.json` removed; only `.env.example` and a test-only secret in `src/test`) |
| 16 | Incomplete functionality documented | ✅ README + this file |

## Not implemented / partial (explicit)
* `notification` backend package and FCM push – not built (local notifications only).
* Doctor profile *edit* screen (API exists), change-password screen (API exists), patient search by doctor, pagination UI ("load more"), charts.
* In-app viewing/downloading of attachments; Flutter widget tests; Flutter integration tests.
* Firestore→MySQL data migration; Flyway; login throttling; refresh tokens.
* Optional LLM assistant (rule-based only, by design).

## Suggested Git history
```
git init && git add . 
chore: import original Flutter prototype assessment and docs
feat(backend): Spring Boot skeleton, MySQL config, error handling
feat(auth): registration, login, JWT with revocation, roles
feat(authz): PatientAccessService, doctor links, caretaker consent
feat(pregnancy): pregnancy profile, progress and weekly catalogue
feat(health): health observations with validation
feat(appointments): booking, conflicts, status workflow
feat(records): medical records with private file storage
feat(medication): medications, reminders, intake tracking
feat(admin): doctor verification, user management, audit log
test(backend): integration and unit tests
feat(frontend): API client, secure storage, providers, theme
feat(ui): patient dashboard and journey redesign
feat(ui): doctor, caretaker and admin screens
docs: README, architecture, schema, API docs, security review
```
(Nothing has been pushed to GitHub by this delivery.)

## Next steps
1. Build & run tests; fix whatever the compilers report. 2. Take screenshots into `docs/screenshots/`. 3. Add Flyway baseline + `ddl-auto=validate`.
4. Add the missing screens listed above. 5. Add GitHub Actions (`mvn test`, `flutter analyze/test`). 6. Security review before any real use.
