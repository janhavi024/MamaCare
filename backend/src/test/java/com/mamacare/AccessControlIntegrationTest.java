package com.mamacare;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Verifies that knowing or guessing another patient's id never grants access. */
class AccessControlIntegrationTest extends ApiTestSupport {

    private void addObservation(Session patient) throws Exception {
        post(patient, "/api/patients/me/health-observations", Map.of("type", "HEART_RATE", "value", 80)).andExpect(status().isCreated());
    }

    @Test
    void patientCannotReadAnotherPatientsData() throws Exception {
        Session a = registerPatient();
        Session b = registerPatient();
        addObservation(a);
        String[] urls = {"/health-observations", "/health-observations/latest", "/pregnancy", "/pregnancy/progress", "/medications",
                "/medications/today", "/records", "/appointments", "/profile"};
        for (String u : urls) get(b, "/api/patients/" + a.id() + u).andExpect(status().isForbidden());
        get(a, "/api/patients/" + a.id() + "/health-observations").andExpect(status().isOk()).andExpect(jsonPath("$.content.length()").value(1));
    }

    @Test
    void patientCannotDeleteAnotherPatientsObservation() throws Exception {
        Session a = registerPatient();
        Session b = registerPatient();
        long id = json(post(a, "/api/patients/me/health-observations", Map.of("type", "HEART_RATE", "value", 70)).andExpect(status().isCreated())).get("id").asLong();
        delete(b, "/api/patients/me/health-observations/" + id).andExpect(status().isForbidden());
        delete(a, "/api/patients/me/health-observations/" + id).andExpect(status().isNoContent());
    }

    @Test
    void doctorNeedsAnAcceptedLink() throws Exception {
        Session patient = registerPatient();
        Session doctor = activeDoctor();
        addObservation(patient);
        get(doctor, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isForbidden());

        long linkId = json(post(patient, "/api/care-links", Map.of("doctorId", doctor.id())).andExpect(status().isCreated())).get("id").asLong();
        // still pending -> still no access
        get(doctor, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isForbidden());
        patch(doctor, "/api/care-links/" + linkId, Map.of("status", "ACCEPTED")).andExpect(status().isOk());
        get(doctor, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isOk());

        // patient revokes -> access ends immediately
        patch(patient, "/api/care-links/" + linkId, Map.of("status", "REVOKED")).andExpect(status().isOk());
        get(doctor, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isForbidden());
    }

    @Test
    void anotherPatientCannotAnswerOrHijackACareLink() throws Exception {
        Session patient = registerPatient();
        Session other = registerPatient();
        Session doctor = activeDoctor();
        long linkId = json(post(patient, "/api/care-links", Map.of("doctorId", doctor.id())).andExpect(status().isCreated())).get("id").asLong();
        patch(other, "/api/care-links/" + linkId, Map.of("status", "REVOKED")).andExpect(status().isForbidden());
        patch(patient, "/api/care-links/" + linkId, Map.of("status", "ACCEPTED")).andExpect(status().isBadRequest()); // patients cannot self-accept
    }

    @Test
    void unverifiedDoctorCannotBeRequestedByPatients() throws Exception {
        Session patient = registerPatient();
        Session pendingDoctor = registerDoctorPending();
        post(patient, "/api/care-links", Map.of("doctorId", pendingDoctor.id())).andExpect(status().isNotFound());
    }

    @Test
    void caretakerAccessFollowsConsentAndPermissionsAndRevocation() throws Exception {
        Session patient = registerPatient();
        Session caretaker = registerCaretaker();
        addObservation(patient);

        // no consent yet
        get(caretaker, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isForbidden());
        post(caretaker, "/api/caretaker/requests", Map.of("patientEmail", patient.email())).andExpect(status().isAccepted());
        get(caretaker, "/api/patients/" + patient.id() + "/medications").andExpect(status().isForbidden()); // pending is not consent

        long accessId = grantCaretaker(patient, caretaker, false, true, false, false);
        get(caretaker, "/api/patients/" + patient.id() + "/medications").andExpect(status().isOk());              // granted
        get(caretaker, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isForbidden()); // not granted
        get(caretaker, "/api/patients/" + patient.id() + "/records").andExpect(status().isForbidden());
        get(caretaker, "/api/patients/" + patient.id() + "/pregnancy/progress").andExpect(status().isOk());
        get(caretaker, "/api/patients/" + patient.id() + "/profile").andExpect(status().isOk()).andExpect(jsonPath("$.email").doesNotExist());

        // caretaker can never write
        post(caretaker, "/api/patients/" + patient.id() + "/medications",
                Map.of("name", "X", "dosage", "1", "frequency", "daily")).andExpect(status().isForbidden());

        patch(patient, "/api/caretaker-access/" + accessId, Map.of("status", "REVOKED")).andExpect(status().isOk());
        get(caretaker, "/api/patients/" + patient.id() + "/medications").andExpect(status().isForbidden());
    }

    @Test
    void caretakerRequestForUnknownEmailLooksIdentical() throws Exception {
        Session caretaker = registerCaretaker();
        post(caretaker, "/api/caretaker/requests", Map.of("patientEmail", "ghost@test.local")).andExpect(status().isAccepted());
    }

    @Test
    void onlyThePatientCanDecideACaretakerRequest() throws Exception {
        Session patient = registerPatient();
        Session caretaker = registerCaretaker();
        post(caretaker, "/api/caretaker/requests", Map.of("patientEmail", patient.email())).andExpect(status().isAccepted());
        long id = json(get(patient, "/api/patients/me/caretaker-access")).get(0).get("id").asLong();
        patch(caretaker, "/api/caretaker-access/" + id, Map.of("status", "GRANTED", "canViewHealth", true)).andExpect(status().isForbidden());
        patch(registerPatient(), "/api/caretaker-access/" + id, Map.of("status", "GRANTED")).andExpect(status().isForbidden());
    }

    @Test
    void adminCannotReadMedicalDataAndPatientsCannotUseAdminApi() throws Exception {
        Session patient = registerPatient();
        addObservation(patient);
        Session admin = admin();
        get(admin, "/api/patients/" + patient.id() + "/health-observations").andExpect(status().isForbidden());
        get(patient, "/api/admin/users").andExpect(status().isForbidden());
        get(registerDoctorPending(), "/api/admin/users").andExpect(status().isForbidden());
        get(admin, "/api/admin/users?role=PATIENT").andExpect(status().isOk());
    }

    @Test
    void adminCannotModifyAdminsOrThemselves() throws Exception {
        Session admin = admin();
        patch(admin, "/api/admin/users/" + admin.id() + "/status", Map.of("status", "SUSPENDED")).andExpect(status().isBadRequest());
    }

    @Test
    void doctorCannotBeActivatedWithoutVerification() throws Exception {
        Session d = registerDoctorPending();
        patch(admin(), "/api/admin/users/" + d.id() + "/status", Map.of("status", "ACTIVE")).andExpect(status().isBadRequest());
    }
}
