# MamaCare – Admin Role Implementation Guide

## Overview
This document describes all changes made to add a full **ADMIN** user role to the MamaCare Flutter + Firebase app, including doctor/patient approval flows, a dedicated admin panel, and role-based access control.

---

## Architecture Understanding (Before Changes)

| Layer | Detail |
|-------|--------|
| **Auth** | Firebase Authentication (email/password) |
| **Database** | Cloud Firestore — two collections: `doctors`, `users` |
| **State** | Provider pattern — `UserProvider` (patient), `DoctorProvider` |
| **Role detection** | Checked at splash/login by querying `doctors/{uid}` — if found → doctor, else → patient |
| **Navigation** | Splash → Login → Home (patient) or DoctorHome (doctor) |
| **Existing roles** | `patient` (users collection), `doctor` (doctors collection) |

---

## What Was Added

### New Files

| File | Purpose |
|------|---------|
| `lib/providers/admin_provider.dart` | Admin state management (mirrors DoctorProvider pattern) |
| `lib/screens/admin_home_screen.dart` | Admin dashboard with 5-tab bottom nav |
| `lib/screens/admin/admin_pending_doctors_screen.dart` | View & approve/reject pending doctor registrations |
| `lib/screens/admin/admin_pending_patients_screen.dart` | View & approve/reject pending patient registrations |
| `lib/screens/admin/admin_doctors_screen.dart` | Browse all doctors by status (approved/pending/rejected) |
| `lib/screens/admin/admin_patients_screen.dart` | Browse all patients by status |
| `lib/screens/pending_approval_screen.dart` | Shown to unapproved users after login/register |
| `firestore.rules` | Production-ready Firestore security rules |

### Modified Files

| File | Change |
|------|--------|
| `lib/main.dart` | Added `AdminProvider` to `MultiProvider` |
| `lib/screens/splash_screen.dart` | Added admin check; added approval-status gating for doctor & patient |
| `lib/screens/login_screen.dart` | Added Admin tab in role toggle; approval-status checks on doctor/patient login |
| `lib/screens/register_screen.dart` | Added `approvalStatus: 'pending'`, `role: 'patient'` to Firestore write; redirects to `PendingApprovalScreen` instead of `HomeScreen` |
| `lib/screens/doctor_register_screen.dart` | Added `approvalStatus: 'pending'`, `role: 'doctor'`, `documents: []` to Firestore write; redirects to `PendingApprovalScreen` |

---

## Firebase Changes Required

### 1. New Firestore Collection: `admins`

Create a new collection called `admins`. Each document ID is the admin's Firebase Auth UID.

**Document structure:**
```json
{
  "name": "Super Admin",
  "email": "admin@mamacare.com",
  "createdAt": "<server timestamp>",
  "role": "admin"
}
```

**How to create the first admin:**
Since there is no admin registration UI (by design — admins are created manually), use one of these methods:

**Option A — Firebase Console:**
1. Go to Firebase Console → Authentication → Add user → enter admin email/password
2. Copy the generated UID
3. Go to Firestore → Create collection `admins` → New document with that UID as document ID
4. Add the fields above

**Option B — Admin SDK script (Node.js):**
```javascript
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.applicationDefault() });

async function createAdmin(email, password, name) {
  const user = await admin.auth().createUser({ email, password });
  await admin.firestore().collection('admins').doc(user.uid).set({
    name,
    email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    role: 'admin',
  });
  console.log('Admin created:', user.uid);
}

createAdmin('admin@mamacare.com', 'SecurePassword123!', 'Super Admin');
```

---

### 2. New Firestore Fields on Existing Collections

#### `doctors` collection — new fields added on registration:

| Field | Type | Values | Description |
|-------|------|---------|-------------|
| `approvalStatus` | String | `pending`, `approved`, `rejected` | Admin approval state |
| `role` | String | `doctor` | Role identifier |
| `documents` | Array | `[{name, url, type}]` | Verification documents (future use) |
| `approvedAt` | Timestamp | null / timestamp | Set when admin approves |
| `rejectedAt` | Timestamp | null / timestamp | Set when admin rejects |

#### `users` (patients) collection — new fields added on registration:

| Field | Type | Values | Description |
|-------|------|---------|-------------|
| `approvalStatus` | String | `pending`, `approved`, `rejected` | Admin approval state |
| `role` | String | `patient` | Role identifier |
| `approvedAt` | Timestamp | null / timestamp | Set when admin approves |
| `rejectedAt` | Timestamp | null / timestamp | Set when admin rejects |

---

### 3. Firestore Indexes Required

The admin screens query with `where` + `orderBy`, which requires composite indexes. Create these in the Firebase Console (Firestore → Indexes → Composite):

| Collection | Fields | Query Scope |
|------------|--------|-------------|
| `doctors` | `approvalStatus` ASC, `createdAt` DESC | Collection |
| `users` | `approvalStatus` ASC, `createdAt` DESC | Collection |

Firebase will also prompt you to create these indexes with a direct link when you first run the app — just click the link in the debug console.

---

### 4. Firebase Storage Rules (if documents are uploaded)

When document upload is implemented, add to your `storage.rules`:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /doctor_documents/{uid}/{fileName} {
      // Doctor can upload their own documents
      allow write: if request.auth != null && request.auth.uid == uid;
      // Admin can read all documents
      allow read: if request.auth != null && (
        request.auth.uid == uid ||
        firestore.get(/databases/(default)/documents/admins/$(request.auth.uid)).data != null
      );
    }
  }
}
```

---

### 5. Updated Firestore Security Rules

Apply the rules in `firestore.rules` to your Firebase project:

```bash
firebase deploy --only firestore:rules
```

Key rule behaviors:
- **Doctors/patients** cannot modify their own `approvalStatus` field
- **Admins** have full read/write on all collections
- **Approved doctors** can read patient records (for clinical use)
- Unapproved users can still read/write their own profile but cannot access others' data

---

## New Firestore Collection Summary

```
admins/
  {uid}/
    name: string
    email: string
    role: "admin"
    createdAt: timestamp

doctors/          (existing — new fields added)
  {uid}/
    ...existing fields...
    approvalStatus: "pending" | "approved" | "rejected"   ← NEW
    role: "doctor"                                         ← NEW
    documents: []                                          ← NEW
    approvedAt: timestamp | null                           ← NEW
    rejectedAt: timestamp | null                           ← NEW

users/            (existing — new fields added)
  {uid}/
    ...existing fields...
    approvalStatus: "pending" | "approved" | "rejected"   ← NEW
    role: "patient"                                        ← NEW
    approvedAt: timestamp | null                           ← NEW
    rejectedAt: timestamp | null                           ← NEW
```

---

## New Dependencies Added

**None.** All new functionality uses existing dependencies already in `pubspec.yaml`:
- `firebase_auth` — already present
- `cloud_firestore` — already present
- `provider` — already present

No `pubspec.yaml` changes needed.

---

## Approval Flow Diagrams

### Doctor Registration Flow
```
Doctor fills DoctorRegisterScreen
    → Firebase Auth account created
    → Firestore doctors/{uid} created with approvalStatus: "pending"
    → Redirected to PendingApprovalScreen
    → Admin sees request in AdminPendingDoctorsScreen
    → Admin approves/rejects
    → Next login: approved → DoctorHomeScreen | rejected → error message
```

### Patient Registration Flow
```
Patient fills RegisterScreen
    → Firebase Auth account created
    → Firestore users/{uid} created with approvalStatus: "pending"
    → Redirected to PendingApprovalScreen
    → Admin sees request in AdminPendingPatientsScreen
    → Admin approves/rejects
    → Next login: approved → HomeScreen | rejected → error message
```

### Admin Login Flow
```
Admin selects "Admin" tab in LoginScreen
    → Firebase Auth sign in
    → Checks admins/{uid} in Firestore
    → If found → AdminHomeScreen
    → If not found → error "No admin account found"
```

---

## Backward Compatibility

Existing doctor/patient accounts in Firestore that **do not have** an `approvalStatus` field will default to `'approved'` in the code:

```dart
final approvalStatus = doctorData?['approvalStatus'] ?? 'approved';
```

This ensures all existing users continue working without any data migration.

---

## Admin Panel Screens

| Tab | Screen | Function |
|-----|--------|---------|
| Dashboard | `_AdminDashboard` | Stats overview, pending alerts, quick actions |
| Dr. Requests | `AdminPendingDoctorsScreen` | Approve/reject pending doctor registrations |
| Pt. Requests | `AdminPendingPatientsScreen` | Approve/reject pending patient registrations |
| Doctors | `AdminDoctorsScreen` | Browse all doctors by status with status-change buttons |
| Patients | `AdminPatientsScreen` | Browse all patients by status with status-change buttons |

---

## Setup Instructions

1. **Deploy Firestore rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Create the first admin manually** (see Firebase Changes → Section 1 above)

3. **Create Firestore composite indexes** for `doctors` and `users` collections (approvalStatus + createdAt)

4. **Run the app** — existing users are unaffected due to the `?? 'approved'` fallback

5. **New registrations** will now require admin approval before accessing the app
