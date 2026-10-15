package com.mamacare.patient;

import com.mamacare.caretaker.AccessStatus;
import com.mamacare.caretaker.CaretakerAccess;
import com.mamacare.caretaker.CaretakerAccessRepository;
import com.mamacare.common.AuthUser;
import com.mamacare.doctor.DoctorPatientLinkRepository;
import com.mamacare.doctor.LinkStatus;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;

/** Pure unit test of the authorization rules (Mockito, no Spring context). */
class PatientAccessServiceTest {
    DoctorPatientLinkRepository links = Mockito.mock(DoctorPatientLinkRepository.class);
    CaretakerAccessRepository caretakers = Mockito.mock(CaretakerAccessRepository.class);
    PatientAccessService service;

    AuthUser patient = new AuthUser(1L, "p@x", Role.PATIENT, AccountStatus.ACTIVE);
    AuthUser doctor = new AuthUser(2L, "d@x", Role.DOCTOR, AccountStatus.ACTIVE);
    AuthUser caretaker = new AuthUser(3L, "c@x", Role.CARETAKER, AccountStatus.ACTIVE);
    AuthUser admin = new AuthUser(4L, "a@x", Role.ADMIN, AccountStatus.ACTIVE);

    @BeforeEach
    void setUp() {
        service = new PatientAccessService(links, caretakers);
        when(links.existsByDoctorIdAndPatientIdAndStatus(anyLong(), anyLong(), Mockito.any())).thenReturn(false);
        when(caretakers.findByPatientIdAndCaretakerIdAndStatus(anyLong(), anyLong(), Mockito.any())).thenReturn(Optional.empty());
    }

    @Test
    void patientOnlyAccessesSelf() {
        for (Scope s : Scope.values()) {
            assertTrue(service.canRead(patient, 1L, s));
            assertFalse(service.canRead(patient, 99L, s));
        }
        assertDoesNotThrow(() -> service.requireWrite(patient, 1L));
        assertThrows(ForbiddenException.class, () -> service.requireWrite(patient, 99L));
    }

    @Test
    void doctorRequiresAcceptedLink() {
        assertFalse(service.canRead(doctor, 1L, Scope.HEALTH));
        when(links.existsByDoctorIdAndPatientIdAndStatus(2L, 1L, LinkStatus.ACCEPTED)).thenReturn(true);
        assertTrue(service.canRead(doctor, 1L, Scope.HEALTH));
        assertFalse(service.canRead(doctor, 5L, Scope.HEALTH));
        assertDoesNotThrow(() -> service.requireWrite(doctor, 1L));
    }

    @Test
    void caretakerIsLimitedToGrantedScopesAndCannotWrite() {
        CaretakerAccess a = new CaretakerAccess();
        a.setStatus(AccessStatus.GRANTED);
        a.setCanViewMedications(true);
        when(caretakers.findByPatientIdAndCaretakerIdAndStatus(1L, 3L, AccessStatus.GRANTED)).thenReturn(Optional.of(a));
        assertTrue(service.canRead(caretaker, 1L, Scope.MEDICATIONS));
        assertTrue(service.canRead(caretaker, 1L, Scope.PREGNANCY));
        assertFalse(service.canRead(caretaker, 1L, Scope.HEALTH));
        assertFalse(service.canRead(caretaker, 1L, Scope.RECORDS));
        assertThrows(ForbiddenException.class, () -> service.requireWrite(caretaker, 1L));
    }

    @Test
    void adminHasNoMedicalDataAccess() {
        for (Scope s : Scope.values()) assertFalse(service.canRead(admin, 1L, s));
        assertThrows(ForbiddenException.class, () -> service.requireRead(admin, 1L, Scope.HEALTH));
    }

    @Test
    void nullInputsAreDenied() {
        assertFalse(service.canRead(null, 1L, Scope.HEALTH));
        assertFalse(service.canRead(patient, null, Scope.HEALTH));
    }
}
