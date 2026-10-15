package com.mamacare.caretaker;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Explicit, revocable consent from a patient for a caretaker, with per-category permissions. */
@Entity
@Table(name = "caretaker_access",
        uniqueConstraints = @UniqueConstraint(name = "uk_access_patient_caretaker", columnNames = {"patient_id", "caretaker_id"}),
        indexes = @Index(name = "idx_access_caretaker_status", columnList = "caretaker_id,status"))
@Getter
@Setter
@NoArgsConstructor
public class CaretakerAccess extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "caretaker_id", nullable = false)
    private User caretaker;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccessStatus status = AccessStatus.PENDING;

    private boolean canViewHealth;
    private boolean canViewMedications;
    private boolean canViewAppointments;
    private boolean canViewRecords;
}
