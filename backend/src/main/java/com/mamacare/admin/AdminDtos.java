package com.mamacare.admin;

import com.mamacare.doctor.VerificationStatus;
import com.mamacare.user.AccountStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public final class AdminDtos {
    private AdminDtos() {}

    public record StatusUpdate(@NotNull AccountStatus status) {}

    /** decision must be APPROVED or REJECTED. */
    public record VerificationDecision(@NotNull VerificationStatus decision, @Size(max = 500) String notes) {}

    public record Stats(long patients, long doctors, long caretakers, long pendingDoctorVerifications, long pendingAccounts) {}

    public record AuditDto(Long id, Long actorId, String action, String entityType, Long entityId, String details, Instant createdAt) {}
}
