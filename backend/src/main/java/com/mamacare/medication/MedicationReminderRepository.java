package com.mamacare.medication;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalTime;
import java.util.Collection;
import java.util.List;

public interface MedicationReminderRepository extends JpaRepository<MedicationReminder, Long> {
    List<MedicationReminder> findByMedicationIdIn(Collection<Long> medicationIds);

    boolean existsByMedicationIdAndTimeOfDay(Long medicationId, LocalTime time);
}
