package com.mamacare.medication;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class MedicationDtos {
    private MedicationDtos() {}

    private static final String HHMM = "^([01]\\d|2[0-3]):[0-5]\\d$";

    /**
     * The app only records medication that the patient or their doctor enters. It never suggests or recommends
     * medication.
     */
    public record MedicationRequest(@NotBlank @Size(max = 120) String name, @NotBlank @Size(max = 80) String dosage,
                                    @NotBlank @Size(max = 60) String frequency, @Size(max = 500) String instructions,
                                    LocalDate startDate, LocalDate endDate,
                                    List<@Pattern(regexp = HHMM, message = "time must be HH:mm") String> reminderTimes) {}

    public record ReminderRequest(@NotBlank @Pattern(regexp = HHMM, message = "time must be HH:mm") String timeOfDay) {}

    public record ReminderToggle(@NotNull Boolean enabled) {}

    public record CompleteRequest(LocalDate date) {}

    public record ReminderDto(Long id, Long medicationId, String timeOfDay, boolean enabled) {}

    public record MedicationDto(Long id, Long patientId, String name, String dosage, String frequency, String instructions,
                                LocalDate startDate, LocalDate endDate, boolean active, Long prescribedById,
                                String prescribedByName, List<ReminderDto> reminders) {}

    public record DoseDto(Long reminderId, Long medicationId, String medicationName, String dosage, String timeOfDay,
                          boolean taken, Instant takenAt) {}
}
