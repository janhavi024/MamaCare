package com.mamacare.pregnancy;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "pregnancies", indexes = @Index(name = "idx_preg_patient_status", columnList = "patient_id,status"))
@Getter
@Setter
@NoArgsConstructor
public class Pregnancy extends BaseEntity {
    public enum Status { ACTIVE, COMPLETED }

    public enum DueDateSource { SELF_REPORTED, LMP_CALCULATED, DOCTOR_CONFIRMED }

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    /** First day of last menstrual period (optional). */
    private LocalDate lmpDate;

    @Column(nullable = false)
    private LocalDate dueDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DueDateSource dueDateSource;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status = Status.ACTIVE;

    @Column(length = 500)
    private String notes;
}
