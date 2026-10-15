package com.mamacare;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MedicalRecordIntegrationTest extends ApiTestSupport {
    private long createRecord(Session creator, long patientId) throws Exception {
        return json(post(creator, "/api/patients/" + patientId + "/records", Map.of("type", "LAB_REPORT", "title", "CBC", "notes", "Hb 11.8"))
                .andExpect(status().isCreated())).get("id").asLong();
    }

    @Test
    void patientUploadsAndDownloadsOwnFileOthersCannot() throws Exception {
        Session p = registerPatient();
        Session other = registerPatient();
        long id = createRecord(p, p.id());
        var file = new MockMultipartFile("file", "cbc.pdf", "application/pdf", "%PDF-1.4 content".getBytes(StandardCharsets.UTF_8));
        mvc.perform(MockMvcRequestBuilders.multipart("/api/records/" + id + "/file").file(file).header("Authorization", "Bearer " + p.token()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.hasFile").value(true)).andExpect(jsonPath("$.fileName").value("cbc.pdf"))
                .andExpect(jsonPath("$.storageKey").doesNotExist());

        get(p, "/api/records/" + id + "/file").andExpect(status().isOk()).andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("attachment")))
                .andExpect(content().contentType("application/pdf"));
        get(other, "/api/records/" + id + "/file").andExpect(status().isForbidden());
        get(other, "/api/records/" + id).andExpect(status().isForbidden());
        get(null, "/api/records/" + id + "/file").andExpect(status().isUnauthorized());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/records/" + id + "/file").file(file).header("Authorization", "Bearer " + other.token()))
                .andExpect(status().isForbidden());
        delete(other, "/api/records/" + id).andExpect(status().isForbidden());
    }

    @Test
    void executableOrDisguisedUploadsAreRejected() throws Exception {
        Session p = registerPatient();
        long id = createRecord(p, p.id());
        var exe = new MockMultipartFile("file", "virus.exe", "application/octet-stream", "MZ".getBytes());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/records/" + id + "/file").file(exe).header("Authorization", "Bearer " + p.token()))
                .andExpect(status().isBadRequest());
        var fake = new MockMultipartFile("file", "fake.pdf", "application/pdf", "<script>alert(1)</script>".getBytes());
        mvc.perform(MockMvcRequestBuilders.multipart("/api/records/" + id + "/file").file(fake).header("Authorization", "Bearer " + p.token()))
                .andExpect(status().isBadRequest());
    }

    @Test
    void recordsFollowDoctorLinkAndCaretakerPermissions() throws Exception {
        Session p = registerPatient();
        Session d = activeDoctor();
        Session c = registerCaretaker();
        long own = createRecord(p, p.id());

        get(d, "/api/patients/" + p.id() + "/records").andExpect(status().isForbidden());
        post(d, "/api/patients/" + p.id() + "/records", Map.of("type", "DOCTOR_NOTE", "title", "Note")).andExpect(status().isForbidden());
        link(p, d);
        long docNote = createRecord(d, p.id());
        get(d, "/api/patients/" + p.id() + "/records").andExpect(jsonPath("$.totalElements").value(2));
        // a doctor cannot delete records the patient uploaded; the patient can delete anything about themselves
        delete(d, "/api/records/" + own).andExpect(status().isForbidden());
        delete(p, "/api/records/" + docNote).andExpect(status().isNoContent());

        grantCaretaker(p, c, true, true, true, false);
        get(c, "/api/patients/" + p.id() + "/records").andExpect(status().isForbidden());
        get(c, "/api/records/" + own).andExpect(status().isForbidden());
    }

    @Test
    void caretakerWithRecordsPermissionCanReadButNotWrite() throws Exception {
        Session p = registerPatient();
        Session c = registerCaretaker();
        long id = createRecord(p, p.id());
        grantCaretaker(p, c, false, false, false, true);
        JsonNode r = json(get(c, "/api/records/" + id).andExpect(status().isOk()));
        assertEquals("CBC", r.get("title").asText());
        post(c, "/api/patients/" + p.id() + "/records", Map.of("type", "OTHER", "title", "x")).andExpect(status().isForbidden());
        delete(c, "/api/records/" + id).andExpect(status().isForbidden());
    }

    @Test
    void validationErrorsOnMetadata() throws Exception {
        Session p = registerPatient();
        post(p, "/api/patients/" + p.id() + "/records", Map.of("type", "OTHER", "title", "")).andExpect(status().isBadRequest());
        post(p, "/api/patients/" + p.id() + "/records", Map.of("title", "no type")).andExpect(status().isBadRequest());
    }
}
