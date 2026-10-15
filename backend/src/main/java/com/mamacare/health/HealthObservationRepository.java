package com.mamacare.health;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Optional;

public interface HealthObservationRepository extends JpaRepository<HealthObservation, Long> {
    Page<HealthObservation> findByPatientIdAndObservedAtBetween(Long patientId, Instant from, Instant to, Pageable pageable);

    Page<HealthObservation> findByPatientIdAndTypeAndObservedAtBetween(Long patientId, ObservationType type, Instant from,
                                                                       Instant to, Pageable pageable);

    Optional<HealthObservation> findFirstByPatientIdAndTypeOrderByObservedAtDesc(Long patientId, ObservationType type);
}
