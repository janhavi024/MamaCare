package com.mamacare.doctor;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/** One row per doctor; resubmission after rejection resets it to PENDING. */
@Entity
@Table(name = "doctor_verifications", indexes = @Index(name = "idx_dv_status", columnList = "status"))
@Getter
@Setter
@NoArgsConstructor
public class DoctorVerification extends BaseEntity {
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "doctor_id", nullable = false, unique = true)
    private User doctor;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VerificationStatus status = VerificationStatus.PENDING;

    @Column(length = 1000)
    private String submittedNotes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    @Column(length = 500)
    private String reviewNotes;

    private Instant reviewedAt;
}
