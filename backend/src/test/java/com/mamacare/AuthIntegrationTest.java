package com.mamacare;

import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthIntegrationTest extends ApiTestSupport {
    @Autowired UserRepository users;

    @Test
    void registrationStoresBcryptHashNeverThePlainPassword() throws Exception {
        Session s = registerPatient();
        User u = users.findById(s.id()).orElseThrow();
        assertNotEquals(PASSWORD, u.getPasswordHash());
        assertTrue(u.getPasswordHash().startsWith("$2"), "expected a BCrypt hash");
    }

    @Test
    void registerThenLoginReturnsTokenAndUser() throws Exception {
        Session s = registerPatient();
        post(null, "/api/auth/login", Map.of("email", s.email(), "password", PASSWORD))
                .andExpect(status().isOk()).andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.role").value("PATIENT")).andExpect(jsonPath("$.user.status").value("ACTIVE"));
    }

    @Test
    void duplicateEmailIsRejected() throws Exception {
        Session s = registerPatient();
        post(null, "/api/auth/register", Map.of("fullName", "X", "email", s.email().toUpperCase(), "password", PASSWORD, "role", "PATIENT"))
                .andExpect(status().isConflict());
    }

    @Test
    void weakPasswordAndBadEmailReturnFieldErrors() throws Exception {
        post(null, "/api/auth/register", Map.of("fullName", "X", "email", "not-an-email", "password", "short", "role", "PATIENT"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.fieldErrors.password").exists())
                .andExpect(jsonPath("$.fieldErrors.email").exists());
    }

    @Test
    void wrongPasswordAndUnknownUserGetTheSameGenericError() throws Exception {
        Session s = registerPatient();
        post(null, "/api/auth/login", Map.of("email", s.email(), "password", "WrongPass123"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.message").value("Invalid email or password"));
        post(null, "/api/auth/login", Map.of("email", "nobody@test.local", "password", "WrongPass123"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void cannotSelfRegisterAsAdmin() throws Exception {
        post(null, "/api/auth/register", Map.of("fullName", "Evil", "email", uniqueEmail("evil"), "password", PASSWORD, "role", "ADMIN"))
                .andExpect(status().isForbidden());
    }

    @Test
    void protectedEndpointsRequireValidToken() throws Exception {
        get(null, "/api/auth/me").andExpect(status().isUnauthorized());
        Session s = registerPatient();
        get(new Session(s.id(), s.email(), s.token() + "x"), "/api/auth/me").andExpect(status().isUnauthorized());
        get(s, "/api/auth/me").andExpect(status().isOk()).andExpect(jsonPath("$.user.email").value(s.email()));
    }

    @Test
    void logoutInvalidatesTheToken() throws Exception {
        Session s = registerPatient();
        post(s, "/api/auth/logout", Map.of()).andExpect(status().isNoContent());
        get(s, "/api/auth/me").andExpect(status().isUnauthorized());
        login(s.email(), PASSWORD);   // can sign in again
    }

    @Test
    void roleCannotBeEscalatedThroughProfileUpdate() throws Exception {
        Session s = registerPatient();
        put(s, "/api/auth/me", Map.of("fullName", "New Name", "role", "ADMIN")).andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("PATIENT"));
        get(s, "/api/admin/stats").andExpect(status().isForbidden());
    }

    @Test
    void pendingDoctorCannotUseDoctorEndpointsUntilApproved() throws Exception {
        Session d = registerDoctorPending();
        get(d, "/api/auth/me").andExpect(status().isOk()).andExpect(jsonPath("$.user.status").value("PENDING"))
                .andExpect(jsonPath("$.verificationStatus").value("PENDING"));
        get(d, "/api/doctors/me").andExpect(status().isForbidden());

        Session approved = activeDoctor();
        get(approved, "/api/doctors/me").andExpect(status().isOk()).andExpect(jsonPath("$.verificationStatus").value("APPROVED"));
    }

    @Test
    void suspendedUserCannotLoginAndExistingTokenStopsWorking() throws Exception {
        Session s = registerPatient();
        patch(admin(), "/api/admin/users/" + s.id() + "/status", Map.of("status", "SUSPENDED")).andExpect(status().isOk());
        get(s, "/api/auth/me").andExpect(status().isUnauthorized());
        post(null, "/api/auth/login", Map.of("email", s.email(), "password", PASSWORD)).andExpect(status().isForbidden());
    }

    @Test
    void errorsNeverLeakStackTraces() throws Exception {
        post(null, "/api/auth/login", "not json").andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value("Malformed request body"));
    }
}
