package com.mamacare.medication;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface MedicationIntakeRepository extends JpaRepository<MedicationIntake, Long> {
    List<MedicationIntake> findByReminderIdInAndIntakeDate(Collection<Long> reminderIds, LocalDate date);

    Optional<MedicationIntake> findByReminderIdAndIntakeDate(Long reminderId, LocalDate date);

    void deleteByReminderId(Long reminderId);
}
