package com.mamacare.medication;

import com.mamacare.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/** Records that a scheduled dose was marked as taken on a given date. */
@Entity
@Table(name = "medication_intakes",
        uniqueConstraints = @UniqueConstraint(name = "uk_intake_reminder_date", columnNames = {"reminder_id", "intakeDate"}))
@Getter
@Setter
@NoArgsConstructor
public class MedicationIntake extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reminder_id", nullable = false)
    private MedicationReminder reminder;

    @Column(nullable = false)
    private LocalDate intakeDate;

    @Column(nullable = false)
    private Instant takenAt;
}
