package com.mamacare.medication;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "medications", indexes = @Index(name = "idx_med_patient_active", columnList = "patient_id,active"))
@Getter
@Setter
@NoArgsConstructor
public class Medication extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    /** Null when the patient entered it themself. Doctor-prescribed entries cannot be edited by the patient. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prescribed_by")
    private User prescribedBy;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, length = 80)
    private String dosage;

    @Column(nullable = false, length = 60)
    private String frequency;

    @Column(length = 500)
    private String instructions;

    @Column(nullable = false)
    private LocalDate startDate;

    private LocalDate endDate;

    @Column(nullable = false)
    private boolean active = true;
}
