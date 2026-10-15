package com.mamacare.pregnancy;

import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ConflictException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.patient.PatientAccessService;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.pregnancy.PregnancyDtos.*;
import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Service
public class PregnancyService {
    private static final int FULL_TERM_DAYS = 280;

    private final PregnancyRepository repo;
    private final UserRepository users;
    private final PatientAccessService access;
    private final AuditService audit;

    public PregnancyService(PregnancyRepository repo, UserRepository users, PatientAccessService access, AuditService audit) {
        this.repo = repo;
        this.users = users;
        this.access = access;
        this.audit = audit;
    }

    /** Used by registration and by the create endpoint. */
    @Transactional
    public Pregnancy createFor(User patient, LocalDate lmp, LocalDate due, String notes) {
        if (repo.existsByPatientIdAndStatus(patient.getId(), Pregnancy.Status.ACTIVE)) {
            throw new ConflictException("An active pregnancy already exists; update it instead");
        }
        Pregnancy p = new Pregnancy();
        p.setPatient(patient);
        apply(p, lmp, due, notes);
        return repo.save(p);
    }

    @Transactional
    public PregnancyDto create(AuthUser me, PregnancyRequest r) {
        Pregnancy p = createFor(users.getReferenceById(me.id()), r.lmpDate(), r.dueDate(), r.notes());
        audit.log(me.id(), "PREGNANCY_CREATED", "Pregnancy", p.getId(), null);
        return toDto(p);
    }

    @Transactional
    public PregnancyDto update(AuthUser me, PregnancyRequest r) {
        Pregnancy p = active(me.id());
        apply(p, r.lmpDate(), r.dueDate(), r.notes());
        return toDto(repo.save(p));
    }

    @Transactional
    public PregnancyDto doctorConfirmDueDate(AuthUser doctor, Long patientId, LocalDate due) {
        access.requireWrite(doctor, patientId);
        validateDue(due);
        Pregnancy p = active(patientId);
        p.setDueDate(due);
        p.setDueDateSource(Pregnancy.DueDateSource.DOCTOR_CONFIRMED);
        audit.log(doctor.id(), "DUE_DATE_CONFIRMED", "Pregnancy", p.getId(), "patientId=" + patientId);
        return toDto(repo.save(p));
    }

    @Transactional
    public PregnancyDto complete(AuthUser me) {
        Pregnancy p = active(me.id());
        p.setStatus(Pregnancy.Status.COMPLETED);
        return toDto(repo.save(p));
    }

    @Transactional(readOnly = true)
    public PregnancyDto get(AuthUser actor, Long patientId) {
        access.requireRead(actor, patientId, Scope.PREGNANCY);
        return toDto(active(patientId));
    }

    @Transactional(readOnly = true)
    public ProgressDto progress(AuthUser actor, Long patientId) {
        access.requireRead(actor, patientId, Scope.PREGNANCY);
        return repo.findFirstByPatientIdAndStatusOrderByCreatedAtDesc(patientId, Pregnancy.Status.ACTIVE)
                .map(p -> progressFor(p.getDueDate(), p.getDueDateSource()))
                .orElse(ProgressDto.none());
    }

    /** Current gestational week for a due date; also used by the doctor's patient list. */
    public Integer completedWeeksFor(Long patientId) {
        return repo.findFirstByPatientIdAndStatusOrderByCreatedAtDesc(patientId, Pregnancy.Status.ACTIVE)
                .map(p -> progressFor(p.getDueDate(), p.getDueDateSource()).completedWeeks()).orElse(null);
    }

    public LocalDate dueDateFor(Long patientId) {
        return repo.findFirstByPatientIdAndStatusOrderByCreatedAtDesc(patientId, Pregnancy.Status.ACTIVE)
                .map(Pregnancy::getDueDate).orElse(null);
    }

    static ProgressDto progressFor(LocalDate due, Pregnancy.DueDateSource source) {
        long daysUntilDue = ChronoUnit.DAYS.between(LocalDate.now(), due);
        long gestDays = Math.max(0, Math.min(FULL_TERM_DAYS + 14, FULL_TERM_DAYS - daysUntilDue));
        int completed = (int) (gestDays / 7);
        int dayInWeek = (int) (gestDays % 7);
        int current = Math.min(40, completed + 1);
        int remaining = Math.max(0, 40 - completed);
        double pct = Math.round(Math.min(1.0, gestDays / (double) FULL_TERM_DAYS) * 1000) / 10.0;
        return new ProgressDto(true, due, completed, dayInWeek, current, remaining, Math.max(0, daysUntilDue),
                PregnancyWeekCatalog.trimesterOf(current), pct, PregnancyWeekCatalog.forWeek(current), source);
    }

    private Pregnancy active(Long patientId) {
        return repo.findFirstByPatientIdAndStatusOrderByCreatedAtDesc(patientId, Pregnancy.Status.ACTIVE)
                .orElseThrow(() -> new ResourceNotFoundException("No active pregnancy found"));
    }

    private void apply(Pregnancy p, LocalDate lmp, LocalDate due, String notes) {
        if (lmp == null && due == null) throw new BadRequestException("Provide your last period date or your due date");
        LocalDate today = LocalDate.now();
        if (lmp != null) {
            if (lmp.isAfter(today)) throw new BadRequestException("Last period date cannot be in the future");
            if (lmp.isBefore(today.minusDays(FULL_TERM_DAYS + 14))) throw new BadRequestException("Last period date is too far in the past");
        }
        if (due != null) {
            validateDue(due);
            p.setDueDate(due);
            p.setDueDateSource(Pregnancy.DueDateSource.SELF_REPORTED);
        } else {
            p.setDueDate(lmp.plusDays(FULL_TERM_DAYS));
            p.setDueDateSource(Pregnancy.DueDateSource.LMP_CALCULATED);
        }
        p.setLmpDate(lmp);
        p.setNotes(notes);
    }

    private void validateDue(LocalDate due) {
        LocalDate today = LocalDate.now();
        if (due.isBefore(today.minusDays(21)) || due.isAfter(today.plusDays(FULL_TERM_DAYS))) {
            throw new BadRequestException("Due date must be within the next 40 weeks");
        }
    }

    private PregnancyDto toDto(Pregnancy p) {
        return new PregnancyDto(p.getId(), p.getPatient().getId(), p.getLmpDate(), p.getDueDate(),
                p.getDueDateSource(), p.getStatus(), p.getNotes());
    }
}
