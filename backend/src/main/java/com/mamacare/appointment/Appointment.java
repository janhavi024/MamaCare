package com.mamacare.appointment;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "appointments", indexes = {
        @Index(name = "idx_appt_doctor_time", columnList = "doctor_id,scheduledAt"),
        @Index(name = "idx_appt_patient_time", columnList = "patient_id,scheduledAt")})
@Getter
@Setter
@NoArgsConstructor
public class Appointment extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "doctor_id", nullable = false)
    private User doctor;

    @Column(nullable = false)
    private Instant scheduledAt;

    @Column(length = 300)
    private String reason;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AppointmentStatus status;

    @Column(length = 500)
    private String doctorNote;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;
}
