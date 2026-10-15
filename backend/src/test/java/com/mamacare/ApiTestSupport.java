package com.mamacare;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Shared helpers: every test talks to the real HTTP layer, security filters and an in-memory H2 database. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public abstract class ApiTestSupport {
    public static final String PASSWORD = "Passw0rdOK";

    @Autowired protected MockMvc mvc;
    @Autowired protected ObjectMapper om;

    public record Session(long id, String email, String token) {}

    protected static String uniqueEmail(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8) + "@test.local";
    }

    protected Session registerPatient() throws Exception {
        return register(Map.of("fullName", "Test Patient", "email", uniqueEmail("patient"), "password", PASSWORD, "role", "PATIENT",
                "dueDate", LocalDate.now().plusDays(150).toString()));
    }

    protected Session registerCaretaker() throws Exception {
        return register(Map.of("fullName", "Test Caretaker", "email", uniqueEmail("care"), "password", PASSWORD, "role", "CARETAKER",
                "relationship", "Husband"));
    }

    protected Session registerDoctorPending() throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("fullName", "Dr Test");
        m.put("email", uniqueEmail("doctor"));
        m.put("password", PASSWORD);
        m.put("role", "DOCTOR");
        m.put("specialization", "Obstetrics");
        m.put("qualification", "MBBS, MD");
        m.put("licenseNumber", "LIC-" + UUID.randomUUID().toString().substring(0, 6));
        m.put("hospital", "Test Hospital");
        return register(m);
    }

    /** Registers a doctor and approves them through the real admin endpoint. */
    protected Session activeDoctor() throws Exception {
        Session d = registerDoctorPending();
        Session admin = admin();
        JsonNode list = json(get(admin, "/api/admin/doctor-verifications?status=PENDING&size=100").andExpect(status().isOk()));
        long verificationId = -1;
        for (JsonNode v : list.get("content")) if (v.get("doctorId").asLong() == d.id()) verificationId = v.get("id").asLong();
        patch(admin, "/api/admin/doctor-verifications/" + verificationId, Map.of("decision", "APPROVED", "notes", "ok")).andExpect(status().isOk());
        return d;
    }

    protected Session admin() throws Exception {
        return login("admin@test.local", "TestAdmin123");
    }

    protected Session register(Map<String, Object> body) throws Exception {
        MvcResult r = mvc.perform(MockMvcRequestBuilders.post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(body))).andExpect(status().isCreated()).andReturn();
        JsonNode n = om.readTree(r.getResponse().getContentAsString());
        return new Session(n.get("user").get("id").asLong(), (String) body.get("email"), n.get("token").asText());
    }

    protected Session login(String email, String password) throws Exception {
        MvcResult r = mvc.perform(MockMvcRequestBuilders.post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(Map.of("email", email, "password", password)))).andExpect(status().isOk()).andReturn();
        JsonNode n = om.readTree(r.getResponse().getContentAsString());
        return new Session(n.get("user").get("id").asLong(), email, n.get("token").asText());
    }

    // ---- request helpers ----
    private MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, Session s) {
        return s == null ? b : b.header("Authorization", "Bearer " + s.token());
    }

    protected ResultActions get(Session s, String url) throws Exception {
        return mvc.perform(auth(MockMvcRequestBuilders.get(url), s));
    }

    protected ResultActions delete(Session s, String url) throws Exception {
        return mvc.perform(auth(MockMvcRequestBuilders.delete(url), s));
    }

    protected ResultActions post(Session s, String url, Object body) throws Exception {
        return mvc.perform(auth(MockMvcRequestBuilders.post(url), s).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body)));
    }

    protected ResultActions put(Session s, String url, Object body) throws Exception {
        return mvc.perform(auth(MockMvcRequestBuilders.put(url), s).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body)));
    }

    protected ResultActions patch(Session s, String url, Object body) throws Exception {
        return mvc.perform(auth(MockMvcRequestBuilders.patch(url), s).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body)));
    }

    protected JsonNode json(ResultActions a) throws Exception {
        return om.readTree(a.andReturn().getResponse().getContentAsString());
    }

    // ---- scenario helpers ----
    /** Patient requests the doctor, doctor accepts. */
    protected void link(Session patient, Session doctor) throws Exception {
        JsonNode l = json(post(patient, "/api/care-links", Map.of("doctorId", doctor.id())).andExpect(status().isCreated()));
        patch(doctor, "/api/care-links/" + l.get("id").asLong(), Map.of("status", "ACCEPTED")).andExpect(status().isOk());
    }

    /** Caretaker asks, patient grants the given permissions. Returns the access id. */
    protected long grantCaretaker(Session patient, Session caretaker, boolean health, boolean meds, boolean appts, boolean records) throws Exception {
        post(caretaker, "/api/caretaker/requests", Map.of("patientEmail", patient.email())).andExpect(status().isAccepted());
        JsonNode list = json(get(patient, "/api/patients/me/caretaker-access").andExpect(status().isOk()));
        long id = -1;
        for (JsonNode a : list) if (a.get("caretakerId").asLong() == caretaker.id()) id = a.get("id").asLong();
        Map<String, Object> d = new LinkedHashMap<>();
        d.put("status", "GRANTED");
        d.put("canViewHealth", health);
        d.put("canViewMedications", meds);
        d.put("canViewAppointments", appts);
        d.put("canViewRecords", records);
        patch(patient, "/api/caretaker-access/" + id, d).andExpect(status().isOk());
        return id;
    }

    protected static String inDays(int days) {
        return Instant.now().plus(days, ChronoUnit.DAYS).truncatedTo(ChronoUnit.MINUTES).toString();
    }
}
