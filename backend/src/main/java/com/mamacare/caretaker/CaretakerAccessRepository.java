package com.mamacare.caretaker;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CaretakerAccessRepository extends JpaRepository<CaretakerAccess, Long> {
    Optional<CaretakerAccess> findByPatientIdAndCaretakerId(Long patientId, Long caretakerId);

    Optional<CaretakerAccess> findByPatientIdAndCaretakerIdAndStatus(Long patientId, Long caretakerId, AccessStatus status);

    List<CaretakerAccess> findByPatientIdOrderByCreatedAtDesc(Long patientId);

    List<CaretakerAccess> findByCaretakerIdOrderByCreatedAtDesc(Long caretakerId);
}
