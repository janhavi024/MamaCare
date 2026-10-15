package com.mamacare.health;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "health_observations",
        indexes = @Index(name = "idx_obs_patient_type_time", columnList = "patient_id,type,observedAt"))
@Getter
@Setter
@NoArgsConstructor
public class HealthObservation extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ObservationType type;

    @Column(nullable = false)
    private double measurement;

    private Double secondaryValue;

    @Column(nullable = false, length = 20)
    private String unit;

    @Column(length = 80)
    private String label;

    @Column(length = 500)
    private String note;

    @Column(nullable = false)
    private Instant observedAt;
}
