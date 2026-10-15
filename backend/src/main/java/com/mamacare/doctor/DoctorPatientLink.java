package com.mamacare.doctor;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/** A patient's request to be under a doctor's care. Only ACCEPTED links grant a doctor access to patient data. */
@Entity
@Table(name = "doctor_patient_links",
        uniqueConstraints = @UniqueConstraint(name = "uk_link_patient_doctor", columnNames = {"patient_id", "doctor_id"}),
        indexes = @Index(name = "idx_link_doctor_status", columnList = "doctor_id,status"))
@Getter
@Setter
@NoArgsConstructor
public class DoctorPatientLink extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "doctor_id", nullable = false)
    private User doctor;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LinkStatus status = LinkStatus.PENDING;

    @Column(length = 500)
    private String message;

    private Instant respondedAt;
}
