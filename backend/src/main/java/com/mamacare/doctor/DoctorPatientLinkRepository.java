package com.mamacare.doctor;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DoctorPatientLinkRepository extends JpaRepository<DoctorPatientLink, Long> {
    boolean existsByDoctorIdAndPatientIdAndStatus(Long doctorId, Long patientId, LinkStatus status);

    Optional<DoctorPatientLink> findByPatientIdAndDoctorId(Long patientId, Long doctorId);

    Page<DoctorPatientLink> findByPatientId(Long patientId, Pageable pageable);

    Page<DoctorPatientLink> findByDoctorId(Long doctorId, Pageable pageable);

    Page<DoctorPatientLink> findByDoctorIdAndStatus(Long doctorId, LinkStatus status, Pageable pageable);
}
