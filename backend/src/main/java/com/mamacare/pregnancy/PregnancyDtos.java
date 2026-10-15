package com.mamacare.pregnancy;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.List;

public final class PregnancyDtos {
    private PregnancyDtos() {}

    /** Provide lmpDate, dueDate or both. If only lmpDate is given, due date = lmp + 280 days. */
    public record PregnancyRequest(LocalDate lmpDate, LocalDate dueDate, @Size(max = 500) String notes) {}

    public record DoctorDueDate(@NotNull LocalDate dueDate) {}

    public record PregnancyDto(Long id, Long patientId, LocalDate lmpDate, LocalDate dueDate,
                               Pregnancy.DueDateSource dueDateSource, Pregnancy.Status status, String notes) {}

    public record WeekInfo(int week, int trimester, String fruit, String size, String description,
                           List<String> milestones) {}

    public record ProgressDto(boolean hasPregnancy, LocalDate dueDate, Integer completedWeeks, Integer daysIntoWeek,
                              Integer currentWeek, Integer remainingWeeks, Long daysUntilDue, Integer trimester,
                              Double percentComplete, WeekInfo weekInfo, Pregnancy.DueDateSource dueDateSource) {
        public static ProgressDto none() {
            return new ProgressDto(false, null, null, null, null, null, null, null, null, null, null);
        }
    }
}
