package com.mamacare.appointment;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.time.Instant;
import java.util.Collection;

public interface AppointmentRepository extends JpaRepository<Appointment, Long>, JpaSpecificationExecutor<Appointment> {
    boolean existsByDoctorIdAndStatusAndScheduledAtBetween(Long doctorId, AppointmentStatus status, Instant from, Instant to);

    boolean existsByPatientIdAndStatusInAndScheduledAtBetween(Long patientId, Collection<AppointmentStatus> statuses, Instant from, Instant to);
}
