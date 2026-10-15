package com.mamacare.pregnancy;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PregnancyRepository extends JpaRepository<Pregnancy, Long> {
    Optional<Pregnancy> findFirstByPatientIdAndStatusOrderByCreatedAtDesc(Long patientId, Pregnancy.Status status);

    boolean existsByPatientIdAndStatus(Long patientId, Pregnancy.Status status);
}
