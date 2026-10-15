package com.mamacare.health;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public final class HealthDtos {
    private HealthDtos() {}

    public record ObservationRequest(@NotNull ObservationType type, @NotNull Double value, Double secondaryValue,
                                     @Size(max = 80) String label, @Size(max = 500) String note, Instant observedAt) {}

    /** source is always USER_ENTERED: these are self-reported values, not clinical findings or advice. */
    public record ObservationDto(Long id, Long patientId, ObservationType type, double value, Double secondaryValue,
                                 String unit, String label, String note, Instant observedAt, String source) {}
}
