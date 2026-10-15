# Phase 1 – Assessment of the original project

Source: `A2_G2_MINPROJECT.zip` → `MamaCare_WithCaretaker.zip` → `mamacare_caretaker/mamacare_fixed`.

## What it was (verified from source)
* **Flutter / Dart** app (`pubspec.yaml`, ~8.4k lines in `lib/`), Material design, **Provider** for state.
* **Firebase Authentication + Cloud Firestore** used *directly from every screen*; no backend, no REST API, no SQL.
* Roles: patient, doctor, caretaker, administrator (separate Firestore collections `users`, `doctors`, `caretakers`, `admins`).
* Features: splash/login/register per role, weekly baby-development data (16 hard-coded weeks), medications, mood tracker,
  prenatal tests list, doctor requests, appointments, doctor reports, doctor-prescribed medications, doctor due-date
  calculator, caretaker dashboard (single linked patient), admin approval of doctors/patients.
* Android only configured (`web/` present). `google-services.json` was committed.

## Reuse / modify / rebuild
| Area | Decision |
|---|---|
| Flutter + Provider + Material | **Kept** (Material 3, Provider for auth & dashboard state) |
| Role model and user journeys (patient/doctor/caretaker/admin, doctor approval, doctor requests, caretaker linking) | **Kept as concepts, re-implemented** on the REST backend |
| Weekly baby data (fruit/size/description) | **Migrated** into `PregnancyWeekCatalog` (now weeks 4-40, remote image URLs dropped) |
| Mood tracker | **Migrated** → `MOOD` and `SYMPTOM` health observations |
| Doctor reports / doctor medications | **Migrated** → medical records (`DOCTOR_NOTE`…) and doctor-prescribed medications |
| Due-date calculator for doctors | **Migrated** → "confirm due date" (`DOCTOR_CONFIRMED`) |
| All Firestore screens/services | **Rewritten**: every screen now talks to the API through `ApiClient` + service classes |
| Firebase Auth/Firestore/Storage dependencies, `google-services.json`, `firestore.rules` | **Removed** (see `legacy-firestore-review.md`) |
| UI | **Redesigned** to the reference image (lavender/white, rounded cards, pill nav) |
| Spring Boot backend, MySQL schema, JWT security, tests, docs | **New** |

## Migration risks
1. **No automatic data migration** from Firestore to MySQL. Existing accounts must re-register (passwords cannot be exported from Firebase Auth in a usable form).
2. "Prenatal tests" checklist screen has no 1:1 replacement: milestones appear in the pregnancy timeline and test results are stored as records.
3. Caretaker model changed from *one linked patient chosen at registration* to *patient-approved, permission-scoped access* (safer, but different UX).
4. Patient approval by admin is now optional (`REQUIRE_PATIENT_APPROVAL=true` restores it); doctors always require verification.
5. Nothing could be compiled/run in the authoring sandbox (no Flutter, Maven or network) – see `PROGRESS.md`.
