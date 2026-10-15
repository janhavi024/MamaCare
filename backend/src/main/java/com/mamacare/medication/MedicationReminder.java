package com.mamacare.medication;

import com.mamacare.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalTime;

@Entity
@Table(name = "medication_reminders",
        uniqueConstraints = @UniqueConstraint(name = "uk_reminder_med_time", columnNames = {"medication_id", "timeOfDay"}))
@Getter
@Setter
@NoArgsConstructor
public class MedicationReminder extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "medication_id", nullable = false)
    private Medication medication;

    @Column(nullable = false)
    private LocalTime timeOfDay;

    @Column(nullable = false)
    private boolean enabled = true;
}
