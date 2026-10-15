package com.mamacare.medication;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MedicationRepository extends JpaRepository<Medication, Long> {
    List<Medication> findByPatientIdOrderByActiveDescCreatedAtDesc(Long patientId);

    List<Medication> findByPatientIdAndActiveTrue(Long patientId);
}
