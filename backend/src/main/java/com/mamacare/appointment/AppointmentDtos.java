package com.mamacare.appointment;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public final class AppointmentDtos {
    private AppointmentDtos() {}

    /** Patients send doctorId; doctors send patientId. The other id is derived from the authenticated user. */
    public record BookRequest(Long doctorId, Long patientId, @NotNull Instant scheduledAt, @Size(max = 300) String reason) {}

    public record StatusUpdate(@NotNull AppointmentStatus status, @Size(max = 500) String note) {}

    public record AppointmentDto(Long id, Long patientId, String patientName, Long doctorId, String doctorName,
                                 Instant scheduledAt, String reason, AppointmentStatus status, String doctorNote,
                                 Instant createdAt) {}
}
