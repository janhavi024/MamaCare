package com.mamacare;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class HealthAndMedicationIntegrationTest extends ApiTestSupport {

    // ---------- health observations ----------
    @Test
    void validObservationsAreStoredWithUnitsAndListedNewestFirst() throws Exception {
        Session p = registerPatient();
        post(p, "/api/patients/me/health-observations", Map.of("type", "BLOOD_PRESSURE", "value", 118, "secondaryValue", 76))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.unit").value("mmHg")).andExpect(jsonPath("$.source").value("USER_ENTERED"));
        post(p, "/api/patients/me/health-observations", Map.of("type", "WEIGHT", "value", 64.5)).andExpect(status().isCreated());
        post(p, "/api/patients/me/health-observations", Map.of("type", "SYMPTOM", "value", 2, "label", "Back pain")).andExpect(status().isCreated());
        get(p, "/api/patients/" + p.id() + "/health-observations").andExpect(status().isOk()).andExpect(jsonPath("$.totalElements").value(3));
        get(p, "/api/patients/" + p.id() + "/health-observations?type=WEIGHT").andExpect(jsonPath("$.totalElements").value(1));
        get(p, "/api/patients/" + p.id() + "/health-observations/latest").andExpect(jsonPath("$.length()").value(3));
    }

    @Test
    void invalidObservationsAreRejected() throws Exception {
        Session p = registerPatient();
        String url = "/api/patients/me/health-observations";
        post(p, url, Map.of("type", "HEART_RATE", "value", 900)).andExpect(status().isBadRequest());                        // out of range
        post(p, url, Map.of("type", "BLOOD_PRESSURE", "value", 120)).andExpect(status().isBadRequest());                    // diastolic missing
        post(p, url, Map.of("type", "BLOOD_PRESSURE", "value", 80, "secondaryValue", 120)).andExpect(status().isBadRequest()); // systolic < diastolic
        post(p, url, Map.of("type", "SYMPTOM", "value", 3)).andExpect(status().isBadRequest());                              // unnamed symptom
        post(p, url, Map.of("type", "WEIGHT")).andExpect(status().isBadRequest());                                           // no value
        post(p, url, Map.of("type", "NOT_A_TYPE", "value", 1)).andExpect(status().isBadRequest());                          // unknown enum
        post(p, url, Map.of("type", "WEIGHT", "value", 60, "observedAt", "2999-01-01T00:00:00Z")).andExpect(status().isBadRequest()); // future
    }

    @Test
    void doctorsCannotRecordObservationsForPatients() throws Exception {
        Session d = activeDoctor();
        post(d, "/api/patients/me/health-observations", Map.of("type", "WEIGHT", "value", 60)).andExpect(status().isForbidden());
    }

    // ---------- pregnancy ----------
    @Test
    void pregnancyCreateProgressAndOnlyOneActive() throws Exception {
        Session p = register(Map.of("fullName", "P", "email", uniqueEmail("preg"), "password", PASSWORD, "role", "PATIENT"));
        get(p, "/api/patients/" + p.id() + "/pregnancy").andExpect(status().isNotFound());
        get(p, "/api/patients/" + p.id() + "/pregnancy/progress").andExpect(jsonPath("$.hasPregnancy").value(false));

        post(p, "/api/patients/me/pregnancy", Map.of("lmpDate", LocalDate.now().minusDays(98).toString())).andExpect(status().isCreated())
                .andExpect(jsonPath("$.dueDateSource").value("LMP_CALCULATED"));
        get(p, "/api/patients/" + p.id() + "/pregnancy/progress").andExpect(jsonPath("$.hasPregnancy").value(true))
                .andExpect(jsonPath("$.completedWeeks").value(14)).andExpect(jsonPath("$.currentWeek").value(15))
                .andExpect(jsonPath("$.trimester").value(2)).andExpect(jsonPath("$.weekInfo.fruit").value("Apple"));
        post(p, "/api/patients/me/pregnancy", Map.of("dueDate", LocalDate.now().plusDays(100).toString())).andExpect(status().isConflict());
        put(p, "/api/patients/me/pregnancy", Map.of("dueDate", LocalDate.now().plusDays(120).toString())).andExpect(status().isOk());
        post(p, "/api/patients/me/pregnancy", Map.of()).andExpect(status().isConflict());
    }

    @Test
    void invalidPregnancyDatesAreRejected() throws Exception {
        Session p = register(Map.of("fullName", "P", "email", uniqueEmail("preg"), "password", PASSWORD, "role", "PATIENT"));
        post(p, "/api/patients/me/pregnancy", Map.of()).andExpect(status().isBadRequest());
        post(p, "/api/patients/me/pregnancy", Map.of("lmpDate", LocalDate.now().plusDays(3).toString())).andExpect(status().isBadRequest());
        post(p, "/api/patients/me/pregnancy", Map.of("dueDate", LocalDate.now().plusDays(500).toString())).andExpect(status().isBadRequest());
    }

    @Test
    void doctorConfirmsDueDateOnlyForLinkedPatient() throws Exception {
        Session p = registerPatient();
        Session d = activeDoctor();
        String due = LocalDate.now().plusDays(90).toString();
        put(d, "/api/patients/" + p.id() + "/pregnancy/due-date", Map.of("dueDate", due)).andExpect(status().isForbidden());
        link(p, d);
        put(d, "/api/patients/" + p.id() + "/pregnancy/due-date", Map.of("dueDate", due)).andExpect(status().isOk())
                .andExpect(jsonPath("$.dueDateSource").value("DOCTOR_CONFIRMED"));
        put(p, "/api/patients/" + p.id() + "/pregnancy/due-date", Map.of("dueDate", due)).andExpect(status().isForbidden());
    }

    @Test
    void timelineCoversWeeks4To40() throws Exception {
        Session p = registerPatient();
        get(p, "/api/pregnancy/timeline").andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(37));
        get(p, "/api/pregnancy/weeks/20").andExpect(jsonPath("$.fruit").value("Banana"));
        get(p, "/api/pregnancy/weeks/2").andExpect(status().isNotFound());
    }

    // ---------- medications ----------
    private Map<String, Object> med(List<String> times) {
        return Map.of("name", "Folic acid", "dosage", "5 mg", "frequency", "Once daily", "reminderTimes", times);
    }

    @Test
    void medicationRemindersCanBeCompletedAndUndone() throws Exception {
        Session p = registerPatient();
        JsonNode m = json(post(p, "/api/patients/" + p.id() + "/medications", med(List.of("08:00", "20:00"))).andExpect(status().isCreated())
                .andExpect(jsonPath("$.reminders.length()").value(2)));
        long medId = m.get("id").asLong();
        String today = LocalDate.now().toString();

        JsonNode doses = json(get(p, "/api/patients/" + p.id() + "/medications/today?date=" + today).andExpect(status().isOk()));
        org.junit.jupiter.api.Assertions.assertEquals(2, doses.size());
        org.junit.jupiter.api.Assertions.assertEquals("08:00", doses.get(0).get("timeOfDay").asText());
        long reminderId = doses.get(0).get("reminderId").asLong();

        post(p, "/api/reminders/" + reminderId + "/complete", Map.of("date", today)).andExpect(status().isOk()).andExpect(jsonPath("$.taken").value(true));
        post(p, "/api/reminders/" + reminderId + "/complete", Map.of("date", today)).andExpect(status().isOk()); // idempotent
        get(p, "/api/patients/" + p.id() + "/medications/today?date=" + today).andExpect(jsonPath("$[0].taken").value(true)).andExpect(jsonPath("$[1].taken").value(false));
        delete(p, "/api/reminders/" + reminderId + "/complete?date=" + today).andExpect(status().isOk()).andExpect(jsonPath("$.taken").value(false));

        post(p, "/api/medications/" + medId + "/reminders", Map.of("timeOfDay", "08:00")).andExpect(status().isConflict());
        post(p, "/api/medications/" + medId + "/reminders", Map.of("timeOfDay", "25:99")).andExpect(status().isBadRequest());
        delete(p, "/api/medications/" + medId).andExpect(status().isOk()).andExpect(jsonPath("$.active").value(false));
        get(p, "/api/patients/" + p.id() + "/medications/today?date=" + today).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void doctorPrescribedMedicationIsProtectedFromPatientEdits() throws Exception {
        Session p = registerPatient();
        Session d = activeDoctor();
        post(d, "/api/patients/" + p.id() + "/medications", med(List.of())).andExpect(status().isForbidden()); // no link yet
        link(p, d);
        long id = json(post(d, "/api/patients/" + p.id() + "/medications", med(List.of("09:00"))).andExpect(status().isCreated())
                .andExpect(jsonPath("$.prescribedByName").value("Dr Test")).andExpect(jsonPath("$.reminders.length()").value(0))).get("id").asLong();

        put(p, "/api/medications/" + id, med(List.of())).andExpect(status().isForbidden());
        delete(p, "/api/medications/" + id).andExpect(status().isForbidden());
        post(p, "/api/medications/" + id + "/reminders", Map.of("timeOfDay", "09:00")).andExpect(status().isCreated()); // personal reminder is allowed
        put(d, "/api/medications/" + id, Map.of("name", "Folic acid", "dosage", "400 mcg", "frequency", "Once daily")).andExpect(status().isOk());
    }

    @Test
    void otherUsersCannotTouchMyRemindersOrMedications() throws Exception {
        Session a = registerPatient();
        Session b = registerPatient();
        JsonNode m = json(post(a, "/api/patients/" + a.id() + "/medications", med(List.of("07:30"))).andExpect(status().isCreated()));
        long medId = m.get("id").asLong();
        long remId = m.get("reminders").get(0).get("id").asLong();
        post(b, "/api/patients/" + a.id() + "/medications", med(List.of())).andExpect(status().isForbidden());
        put(b, "/api/medications/" + medId, med(List.of())).andExpect(status().isForbidden());
        post(b, "/api/reminders/" + remId + "/complete", Map.of()).andExpect(status().isForbidden());
        delete(b, "/api/reminders/" + remId).andExpect(status().isForbidden());
        post(b, "/api/medications/" + medId + "/reminders", Map.of("timeOfDay", "10:00")).andExpect(status().isForbidden());
    }

    @Test
    void medicationValidation() throws Exception {
        Session p = registerPatient();
        post(p, "/api/patients/" + p.id() + "/medications", Map.of("name", "", "dosage", "1", "frequency", "daily")).andExpect(status().isBadRequest());
        post(p, "/api/patients/" + p.id() + "/medications", Map.of("name", "X", "dosage", "1", "frequency", "daily",
                "startDate", "2026-05-10", "endDate", "2026-05-01")).andExpect(status().isBadRequest());
    }

    @Test
    void assistantEscalatesEmergenciesAndNeverRecommendsMedicine() throws Exception {
        Session p = registerPatient();
        post(p, "/api/assistant/ask", Map.of("question", "I have heavy bleeding and severe pain")).andExpect(status().isOk())
                .andExpect(jsonPath("$.urgent").value(true));
        post(p, "/api/assistant/ask", Map.of("question", "Can I take paracetamol?")).andExpect(jsonPath("$.urgent").value(false))
                .andExpect(jsonPath("$.answer").value(org.hamcrest.Matchers.containsString("can't recommend")));
        post(p, "/api/assistant/ask", Map.of("question", "what week am I in")).andExpect(jsonPath("$.answer").value(org.hamcrest.Matchers.containsString("week")));
        post(p, "/api/assistant/ask", Map.of("question", "")).andExpect(status().isBadRequest());
    }
}
