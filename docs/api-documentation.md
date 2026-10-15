# REST API

Base URL (emulator): `http://10.0.2.2:8080` · (host): `http://localhost:8080`.
All endpoints except `register`/`login` need `Authorization: Bearer <jwt>`. JSON only (files use multipart). Pagination: `?page=0&size=20&sort=field,desc` (max size 100).
Dates: `yyyy-MM-dd`; instants: ISO-8601 UTC (`2026-10-20T09:30:00Z`).

Errors always look like:
```json
{ "timestamp": "...", "status": 400, "error": "Bad Request", "message": "Validation failed", "path": "/api/auth/register",
  "fieldErrors": { "password": "must be 8-72 characters and contain a letter and a number" } }
```
`401` missing/invalid/revoked token · `403` not allowed · `404` not found · `409` conflict · `413` file too large.
Success responses are the DTO itself (or `{content,page,size,totalElements,totalPages}` for pages).

## Auth
| Method | Path | Who | Notes |
|---|---|---|---|
| POST | `/api/auth/register` | public | role PATIENT/DOCTOR/CARETAKER only (ADMIN ⇒ 403). Doctors need specialization, qualification, licenseNumber |
| POST | `/api/auth/login` | public | → `{token, expiresAt, user}` |
| GET | `/api/auth/me` | any signed-in | includes doctor `verificationStatus` |
| PUT | `/api/auth/me` | any | name, phone (role can't be changed) |
| POST | `/api/auth/logout` | any | revokes all tokens of the user |
| POST | `/api/auth/change-password` | any | returns a fresh token |

## Pregnancy (`{patientId}` = the patient's user id; access checked server-side)
| Method | Path | Who |
|---|---|---|
| POST | `/api/patients/me/pregnancy` `{lmpDate?, dueDate?, notes?}` | patient |
| PUT | `/api/patients/me/pregnancy` | patient |
| POST | `/api/patients/me/pregnancy/complete` | patient |
| GET | `/api/patients/{patientId}/pregnancy` | self / linked doctor / granted caretaker |
| GET | `/api/patients/{patientId}/pregnancy/progress` | same |
| PUT | `/api/patients/{patientId}/pregnancy/due-date` `{dueDate}` | linked doctor |
| GET | `/api/pregnancy/timeline`, `/api/pregnancy/weeks/{4..40}` | signed-in |
| GET/PUT | `/api/patients/me/profile` · GET `/api/patients/{id}/profile` | patient · authorized viewers (caretakers get a minimal view) |

## Health observations
| Method | Path | Who |
|---|---|---|
| POST | `/api/patients/me/health-observations` `{type, value, secondaryValue?, label?, note?, observedAt?}` | patient |
| GET | `/api/patients/{patientId}/health-observations?type=&from=&to=` | self / doctor / caretaker with *health* permission |
| GET | `/api/patients/{patientId}/health-observations/latest` | same |
| DELETE | `/api/patients/me/health-observations/{id}` | owner |

Types and units: `WEIGHT` kg · `BLOOD_PRESSURE` mmHg (value=systolic, secondaryValue=diastolic) · `HEART_RATE` bpm · `BLOOD_GLUCOSE` mg/dL ·
`BODY_TEMPERATURE` °C · `URINE_PH` pH · `SYMPTOM` (label required, severity 1-5) · `MOOD` 1-5. Ranges only catch typing errors; the API gives no clinical interpretation.

## Appointments
| Method | Path | Who |
|---|---|---|
| GET | `/api/appointments?status=&from=` | patient / doctor (own) |
| POST | `/api/appointments` | patient `{doctorId, scheduledAt, reason?}` → REQUESTED · doctor `{patientId, scheduledAt}` (linked patients) → CONFIRMED |
| GET | `/api/appointments/{id}` | participants, or caretaker with *appointments* permission |
| PATCH | `/api/appointments/{id}/status` `{status, note?}` | patient: CANCELLED (future only) · doctor: CONFIRMED/DECLINED/COMPLETED/CANCELLED |
| GET | `/api/patients/{patientId}/appointments` | self / doctor / caretaker with permission |

## Doctors and care links
`GET /api/doctors?q=` (patients; verified doctors only) · `GET|PUT /api/doctors/me` · `POST /api/doctors/me/verification {licenseNumber, notes}` ·
`GET /api/doctors/me/patients` · `POST /api/care-links {doctorId, message?}` (patient) · `GET /api/care-links?status=` · `PATCH /api/care-links/{id} {status}`
(doctor: ACCEPTED/DECLINED; either side: REVOKED).

## Caretakers
`POST /api/caretaker/requests {patientEmail}` (always 202) · `GET /api/caretaker/patients` · `DELETE /api/caretaker/access/{id}` ·
`GET /api/patients/me/caretaker-access` (patient) · `PATCH /api/caretaker-access/{id} {status: GRANTED|REJECTED|REVOKED, canViewHealth, canViewMedications, canViewAppointments, canViewRecords}` (patient only).

## Medical records
`GET /api/patients/{id}/records` · `POST /api/patients/{id}/records {type,title,notes?,recordDate?}` (patient or linked doctor) ·
`GET /api/records/{id}` · `POST /api/records/{id}/file` (multipart field `file`; pdf/png/jpg ≤10 MB) · `GET /api/records/{id}/file` (download) · `DELETE /api/records/{id}` (patient, or uploader).

## Medications and reminders
`GET /api/patients/{id}/medications?activeOnly=` · `POST /api/patients/{id}/medications {name,dosage,frequency,instructions?,startDate?,endDate?,reminderTimes?["08:00"]}` ·
`PUT /api/medications/{id}` · `DELETE /api/medications/{id}` (archives) · `POST /api/medications/{id}/reminders {timeOfDay}` · `PATCH /api/reminders/{id} {enabled}` ·
`DELETE /api/reminders/{id}` · `GET /api/patients/{id}/medications/today?date=` · `POST /api/reminders/{id}/complete {date?}` · `DELETE /api/reminders/{id}/complete?date=`.
Doctor-prescribed medicines cannot be edited/archived by the patient (reminders for them can be).

## Admin (ADMIN only)
`GET /api/admin/stats` · `GET /api/admin/users?role=&status=&q=` · `PATCH /api/admin/users/{id}/status {status}` ·
`GET /api/admin/doctor-verifications?status=` · `PATCH /api/admin/doctor-verifications/{id} {decision: APPROVED|REJECTED, notes}` · `GET /api/admin/audit-logs`.

## Assistant (PATIENT)
`POST /api/assistant/ask {question}` → `{answer, urgent, disclaimer}` (rule-based; emergencies are escalated; never recommends medicine).

## Try it with curl
```bash
BASE=http://localhost:8080
curl -s -X POST $BASE/api/auth/register -H 'Content-Type: application/json' \
  -d '{"fullName":"Asha Patil","email":"asha@example.com","password":"Passw0rd123","role":"PATIENT","dueDate":"2027-02-10"}'
TOKEN=$(curl -s -X POST $BASE/api/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"asha@example.com","password":"Passw0rd123"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')
curl -s $BASE/api/auth/me -H "Authorization: Bearer $TOKEN"
curl -s -X POST $BASE/api/patients/me/health-observations -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"type":"HEART_RATE","value":85}'
```
In Postman: *Import → Raw text* is not needed; create an environment variable `token` and use `Bearer {{token}}`.
