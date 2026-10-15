package com.mamacare.doctor;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "doctor_profiles")
@Getter
@Setter
@NoArgsConstructor
public class DoctorProfile extends BaseEntity {
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false, length = 80)
    private String specialization;

    @Column(nullable = false, length = 120)
    private String qualification;

    @Column(length = 150)
    private String hospital;

    @Column(length = 60)
    private String licenseNumber;

    private Integer yearsOfExperience;

    @Column(length = 1000)
    private String bio;
}
