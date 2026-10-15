package com.mamacare.appointment;

import com.mamacare.appointment.AppointmentDtos.*;
import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ConflictException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.patient.PatientAccessService;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;
import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Service
public class AppointmentService {
    /** Appointments occupy a fixed 30-minute slot. */
    private static final long SLOT_MINUTES = 30;

    private final AppointmentRepository repo;
    private final UserRepository users;
    private final PatientAccessService access;
    private final AuditService audit;

    public AppointmentService(AppointmentRepository repo, UserRepository users, PatientAccessService access, AuditService audit) {
        this.repo = repo;
        this.users = users;
        this.access = access;
        this.audit = audit;
    }

    @Transactional
    public AppointmentDto create(AuthUser me, BookRequest r) {
        if (!r.scheduledAt().isAfter(Instant.now().plus(5, ChronoUnit.MINUTES))) {
            throw new BadRequestException("Appointment time must be in the future");
        }
        if (r.scheduledAt().isAfter(Instant.now().plus(365, ChronoUnit.DAYS))) {
            throw new BadRequestException("Appointments can be booked up to one year ahead");
        }
        User patient;
        User doctor;
        AppointmentStatus status;
        if (me.role() == Role.PATIENT) {
            if (r.doctorId() == null) throw new BadRequestException("doctorId is required");
            doctor = users.findById(r.doctorId()).filter(u -> u.getRole() == Role.DOCTOR && u.getStatus() == AccountStatus.ACTIVE)
                    .orElseThrow(() -> new ResourceNotFoundException("Doctor not found"));
            patient = users.getReferenceById(me.id());
            status = AppointmentStatus.REQUESTED;
        } else if (me.role() == Role.DOCTOR) {
            if (r.patientId() == null) throw new BadRequestException("patientId is required");
            access.requireWrite(me, r.patientId());   // doctor must have an accepted link with this patient
            patient = users.findById(r.patientId()).orElseThrow(() -> new ResourceNotFoundException("Patient not found"));
            doctor = users.getReferenceById(me.id());
            status = AppointmentStatus.CONFIRMED;
        } else {
            throw new ForbiddenException("Only patients and doctors can create appointments");
        }
        if (slotTaken(doctor.getId(), r.scheduledAt())) throw new ConflictException("That time slot is not available");
        if (patientBusy(patient.getId(), r.scheduledAt())) throw new ConflictException("The patient already has an appointment at that time");

        Appointment a = new Appointment();
        a.setPatient(patient);
        a.setDoctor(doctor);
        a.setScheduledAt(r.scheduledAt());
        a.setReason(r.reason() == null || r.reason().isBlank() ? null : r.reason().trim());
        a.setStatus(status);
        a.setCreatedBy(users.getReferenceById(me.id()));
        a = repo.save(a);
        audit.log(me.id(), "APPOINTMENT_CREATED", "Appointment", a.getId(), null);
        return toDto(a);
    }

    @Transactional(readOnly = true)
    public PageResponse<AppointmentDto> list(AuthUser me, AppointmentStatus status, Instant from, Pageable pageable) {
        Specification<Appointment> spec = (root, q, cb) -> {
            List<Predicate> ps = new ArrayList<>();
            ps.add(cb.equal(root.get(me.role() == Role.DOCTOR ? "doctor" : "patient").get("id"), me.id()));
            if (status != null) ps.add(cb.equal(root.get("status"), status));
            if (from != null) ps.add(cb.greaterThanOrEqualTo(root.get("scheduledAt"), from));
            return cb.and(ps.toArray(new Predicate[0]));
        };
        return PageResponse.of(repo.findAll(spec, pageable), this::toDto);
    }

    /** Appointments of one patient, for a caretaker (with permission) or the patient's linked doctor. */
    @Transactional(readOnly = true)
    public PageResponse<AppointmentDto> forPatient(AuthUser actor, Long patientId, Instant from, Pageable pageable) {
        access.requireRead(actor, patientId, Scope.APPOINTMENTS);
        Specification<Appointment> spec = (root, q, cb) -> {
            Predicate p = cb.equal(root.get("patient").get("id"), patientId);
            return from == null ? p : cb.and(p, cb.greaterThanOrEqualTo(root.get("scheduledAt"), from));
        };
        return PageResponse.of(repo.findAll(spec, pageable), this::toDto);
    }

    @Transactional(readOnly = true)
    public AppointmentDto get(AuthUser me, Long id) {
        Appointment a = find(id);
        boolean participant = a.getPatient().getId().equals(me.id()) || a.getDoctor().getId().equals(me.id());
        if (!participant && !access.canRead(me, a.getPatient().getId(), Scope.APPOINTMENTS)) {
            throw new ForbiddenException("You do not have access to this appointment");
        }
        return toDto(a);
    }

    @Transactional
    public AppointmentDto updateStatus(AuthUser me, Long id, StatusUpdate u) {
        Appointment a = find(id);
        AppointmentStatus cur = a.getStatus();
        AppointmentStatus target = u.status();
        boolean isPatient = me.role() == Role.PATIENT && a.getPatient().getId().equals(me.id());
        boolean isDoctor = me.role() == Role.DOCTOR && a.getDoctor().getId().equals(me.id());
        if (!isPatient && !isDoctor) throw new ForbiddenException("You cannot change this appointment");

        boolean active = cur == AppointmentStatus.REQUESTED || cur == AppointmentStatus.CONFIRMED;
        boolean allowed;
        if (isPatient) {
            // patients may only cancel, and only before it starts
            allowed = target == AppointmentStatus.CANCELLED && active && a.getScheduledAt().isAfter(Instant.now());
        } else {
            allowed = switch (target) {
                case CONFIRMED, DECLINED -> cur == AppointmentStatus.REQUESTED;
                case COMPLETED -> cur == AppointmentStatus.CONFIRMED;
                case CANCELLED -> active;
                default -> false;
            };
        }
        if (!allowed) throw new BadRequestException("Cannot change a " + cur.name().toLowerCase() + " appointment to " + target.name().toLowerCase());
        if (target == AppointmentStatus.CONFIRMED && slotTaken(a.getDoctor().getId(), a.getScheduledAt())) {
            throw new ConflictException("You already have a confirmed appointment at that time");
        }
        a.setStatus(target);
        if (isDoctor && u.note() != null && !u.note().isBlank()) a.setDoctorNote(u.note().trim());
        audit.log(me.id(), "APPOINTMENT_" + target, "Appointment", a.getId(), null);
        return toDto(repo.save(a));
    }

    private boolean slotTaken(Long doctorId, Instant at) {
        return repo.existsByDoctorIdAndStatusAndScheduledAtBetween(doctorId, AppointmentStatus.CONFIRMED,
                at.minus(SLOT_MINUTES - 1, ChronoUnit.MINUTES), at.plus(SLOT_MINUTES - 1, ChronoUnit.MINUTES));
    }

    private boolean patientBusy(Long patientId, Instant at) {
        return repo.existsByPatientIdAndStatusInAndScheduledAtBetween(patientId,
                List.of(AppointmentStatus.REQUESTED, AppointmentStatus.CONFIRMED),
                at.minus(SLOT_MINUTES - 1, ChronoUnit.MINUTES), at.plus(SLOT_MINUTES - 1, ChronoUnit.MINUTES));
    }

    private Appointment find(Long id) {
        return repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Appointment not found"));
    }

    private AppointmentDto toDto(Appointment a) {
        return new AppointmentDto(a.getId(), a.getPatient().getId(), a.getPatient().getFullName(), a.getDoctor().getId(),
                a.getDoctor().getFullName(), a.getScheduledAt(), a.getReason(), a.getStatus(), a.getDoctorNote(), a.getCreatedAt());
    }
}
