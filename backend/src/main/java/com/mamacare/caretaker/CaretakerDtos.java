package com.mamacare.caretaker;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public final class CaretakerDtos {
    private CaretakerDtos() {}

    public record AccessRequest(@NotBlank @Email String patientEmail) {}

    /** status: GRANTED or REJECTED (for PENDING), GRANTED (to edit permissions) or REVOKED. */
    public record AccessDecision(@NotNull AccessStatus status, Boolean canViewHealth, Boolean canViewMedications,
                                 Boolean canViewAppointments, Boolean canViewRecords) {}

    public record AccessDto(Long id, Long patientId, String patientName, Long caretakerId, String caretakerName,
                            String caretakerEmail, AccessStatus status, boolean canViewHealth,
                            boolean canViewMedications, boolean canViewAppointments, boolean canViewRecords,
                            Instant createdAt) {
        public static AccessDto from(CaretakerAccess a) {
            return new AccessDto(a.getId(), a.getPatient().getId(), a.getPatient().getFullName(),
                    a.getCaretaker().getId(), a.getCaretaker().getFullName(), a.getCaretaker().getEmail(),
                    a.getStatus(), a.isCanViewHealth(), a.isCanViewMedications(), a.isCanViewAppointments(),
                    a.isCanViewRecords(), a.getCreatedAt());
        }
    }
}
