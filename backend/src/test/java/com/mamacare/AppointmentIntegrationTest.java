package com.mamacare;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AppointmentIntegrationTest extends ApiTestSupport {

    private long book(Session patient, Session doctor, String when) throws Exception {
        return json(post(patient, "/api/appointments", Map.of("doctorId", doctor.id(), "scheduledAt", when, "reason", "Check-up"))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.status").value("REQUESTED"))).get("id").asLong();
    }

    @Test
    void bookConfirmAndListEndToEnd() throws Exception {
        Session patient = registerPatient();
        Session doctor = activeDoctor();
        long id = book(patient, doctor, inDays(3));

        get(doctor, "/api/appointments?status=REQUESTED").andExpect(status().isOk()).andExpect(jsonPath("$.content[0].id").value(id));
        patch(doctor, "/api/appointments/" + id + "/status", Map.of("status", "CONFIRMED", "note", "See you")).andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CONFIRMED")).andExpect(jsonPath("$.doctorNote").value("See you"));
        get(patient, "/api/appointments/" + id).andExpect(status().isOk()).andExpect(jsonPath("$.doctorName").value("Dr Test"));
        patch(doctor, "/api/appointments/" + id + "/status", Map.of("status", "COMPLETED")).andExpect(status().isOk());
        // completed appointments cannot be cancelled
        patch(patient, "/api/appointments/" + id + "/status", Map.of("status", "CANCELLED")).andExpect(status().isBadRequest());
    }

    @Test
    void pastAndTooFarDatesAreRejected() throws Exception {
        Session patient = registerPatient();
        Session doctor = activeDoctor();
        post(patient, "/api/appointments", Map.of("doctorId", doctor.id(), "scheduledAt", inDays(-1))).andExpect(status().isBadRequest());
        post(patient, "/api/appointments", Map.of("doctorId", doctor.id(), "scheduledAt", inDays(400))).andExpect(status().isBadRequest());
        post(patient, "/api/appointments", Map.of("doctorId", doctor.id())).andExpect(status().isBadRequest()); // missing time
    }

    @Test
    void confirmedSlotCannotBeDoubleBooked() throws Exception {
        Session p1 = registerPatient();
        Session p2 = registerPatient();
        Session doctor = activeDoctor();
        String slot = inDays(5);
        long id = book(p1, doctor, slot);
        patch(doctor, "/api/appointments/" + id + "/status", Map.of("status", "CONFIRMED")).andExpect(status().isOk());
        post(p2, "/api/appointments", Map.of("doctorId", doctor.id(), "scheduledAt", slot)).andExpect(status().isConflict());
        // 15 minutes later still overlaps the 30-minute slot, 30 minutes later is free
        String overlapping = Instant.parse(slot).plus(15, ChronoUnit.MINUTES).toString();
        post(p2, "/api/appointments", Map.of("doctorId", doctor.id(), "scheduledAt", overlapping)).andExpect(status().isConflict());
        String free = Instant.parse(slot).plus(30, ChronoUnit.MINUTES).toString();
        post(p2, "/api/appointments", Map.of("doctorId", doctor.id(), "scheduledAt", free)).andExpect(status().isCreated());
    }

    @Test
    void patientCannotBeDoubleBookedWithTwoDoctors() throws Exception {
        Session patient = registerPatient();
        Session d1 = activeDoctor();
        Session d2 = activeDoctor();
        String slot = inDays(6);
        book(patient, d1, slot);
        post(patient, "/api/appointments", Map.of("doctorId", d2.id(), "scheduledAt", slot)).andExpect(status().isConflict());
    }

    @Test
    void onlyParticipantsCanSeeOrChangeAnAppointment() throws Exception {
        Session patient = registerPatient();
        Session stranger = registerPatient();
        Session doctor = activeDoctor();
        Session otherDoctor = activeDoctor();
        long id = book(patient, doctor, inDays(4));

        get(stranger, "/api/appointments/" + id).andExpect(status().isForbidden());
        patch(stranger, "/api/appointments/" + id + "/status", Map.of("status", "CANCELLED")).andExpect(status().isForbidden());
        patch(otherDoctor, "/api/appointments/" + id + "/status", Map.of("status", "CONFIRMED")).andExpect(status().isForbidden());
        // patients cannot confirm their own appointment
        patch(patient, "/api/appointments/" + id + "/status", Map.of("status", "CONFIRMED")).andExpect(status().isBadRequest());
        patch(patient, "/api/appointments/" + id + "/status", Map.of("status", "CANCELLED")).andExpect(status().isOk());
    }

    @Test
    void doctorSchedulesForLinkedPatientsOnly() throws Exception {
        Session patient = registerPatient();
        Session doctor = activeDoctor();
        post(doctor, "/api/appointments", Map.of("patientId", patient.id(), "scheduledAt", inDays(7))).andExpect(status().isForbidden());
        link(patient, doctor);
        JsonNode a = json(post(doctor, "/api/appointments", Map.of("patientId", patient.id(), "scheduledAt", inDays(7), "reason", "Scan"))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.status").value("CONFIRMED")));
        get(patient, "/api/appointments").andExpect(status().isOk()).andExpect(jsonPath("$.content[0].id").value(a.get("id").asLong()));
    }

    @Test
    void caretakerSeesAppointmentsOnlyWithPermission() throws Exception {
        Session patient = registerPatient();
        Session doctor = activeDoctor();
        Session caretaker = registerCaretaker();
        book(patient, doctor, inDays(8));
        grantCaretaker(patient, caretaker, false, false, true, false);
        get(caretaker, "/api/patients/" + patient.id() + "/appointments").andExpect(status().isOk()).andExpect(jsonPath("$.content.length()").value(1));
    }
}
