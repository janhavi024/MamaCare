package com.mamacare.doctor;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DoctorVerificationRepository extends JpaRepository<DoctorVerification, Long> {
    Optional<DoctorVerification> findByDoctorId(Long doctorId);

    Page<DoctorVerification> findByStatus(VerificationStatus status, Pageable pageable);
}
