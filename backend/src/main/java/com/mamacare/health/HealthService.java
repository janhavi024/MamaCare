package com.mamacare.health;

import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.health.HealthDtos.*;
import com.mamacare.patient.PatientAccessService;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.user.Role;
import com.mamacare.user.UserRepository;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Service
public class HealthService {
    private final HealthObservationRepository repo;
    private final UserRepository users;
    private final PatientAccessService access;
    private final AuditService audit;

    public HealthService(HealthObservationRepository repo, UserRepository users, PatientAccessService access, AuditService audit) {
        this.repo = repo;
        this.users = users;
        this.access = access;
        this.audit = audit;
    }

    @Transactional
    public ObservationDto record(AuthUser me, ObservationRequest r) {
        ObservationType t = r.type();
        double v = r.value();
        if (v < t.min || v > t.max) throw new BadRequestException(t.name() + " value must be between " + t.min + " and " + t.max + " " + t.unit);
        Double sec = r.secondaryValue();
        if (t.hasSecondary) {
            if (sec == null) throw new BadRequestException("Both systolic and diastolic values are required");
            if (sec < t.secondaryMin || sec > t.secondaryMax) throw new BadRequestException("Diastolic value is outside the plausible range");
            if (sec >= v) throw new BadRequestException("Systolic value must be higher than diastolic value");
        } else {
            sec = null;
        }
        if (t == ObservationType.SYMPTOM && (r.label() == null || r.label().isBlank())) {
            throw new BadRequestException("Please name the symptom");
        }
        Instant when = r.observedAt() == null ? Instant.now() : r.observedAt();
        if (when.isAfter(Instant.now().plus(5, ChronoUnit.MINUTES))) throw new BadRequestException("Measurement time cannot be in the future");

        HealthObservation o = new HealthObservation();
        o.setPatient(users.getReferenceById(me.id()));
        o.setType(t);
        o.setMeasurement(v);
        o.setSecondaryValue(sec);
        o.setUnit(t.unit);
        o.setLabel(r.label() == null || r.label().isBlank() ? null : r.label().trim());
        o.setNote(r.note() == null || r.note().isBlank() ? null : r.note().trim());
        o.setObservedAt(when);
        return toDto(repo.save(o));
    }

    @Transactional(readOnly = true)
    public PageResponse<ObservationDto> list(AuthUser actor, Long patientId, ObservationType type, Instant from, Instant to, Pageable pageable) {
        access.requireRead(actor, patientId, Scope.HEALTH);
        auditIfNotOwner(actor, patientId, "HEALTH_DATA_VIEWED");
        Instant f = from == null ? Instant.EPOCH : from;
        Instant t = to == null ? Instant.now().plus(1, ChronoUnit.DAYS) : to;
        var page = type == null ? repo.findByPatientIdAndObservedAtBetween(patientId, f, t, pageable)
                : repo.findByPatientIdAndTypeAndObservedAtBetween(patientId, type, f, t, pageable);
        return PageResponse.of(page, this::toDto);
    }

    /** Most recent reading of each type (for dashboard cards). */
    @Transactional(readOnly = true)
    public List<ObservationDto> latest(AuthUser actor, Long patientId) {
        access.requireRead(actor, patientId, Scope.HEALTH);
        auditIfNotOwner(actor, patientId, "HEALTH_DATA_VIEWED");
        List<ObservationDto> out = new ArrayList<>();
        for (ObservationType t : ObservationType.values()) {
            repo.findFirstByPatientIdAndTypeOrderByObservedAtDesc(patientId, t).ifPresent(o -> out.add(toDto(o)));
        }
        return out;
    }

    @Transactional
    public void delete(AuthUser me, Long id) {
        HealthObservation o = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Observation not found"));
        if (me.role() != Role.PATIENT || !o.getPatient().getId().equals(me.id())) throw new ForbiddenException("You can only delete your own entries");
        repo.delete(o);
    }

    private void auditIfNotOwner(AuthUser actor, Long patientId, String action) {
        if (!actor.id().equals(patientId)) audit.log(actor.id(), action, "Patient", patientId, null);
    }

    private ObservationDto toDto(HealthObservation o) {
        return new ObservationDto(o.getId(), o.getPatient().getId(), o.getType(), o.getMeasurement(), o.getSecondaryValue(),
                o.getUnit(), o.getLabel(), o.getNote(), o.getObservedAt(), "USER_ENTERED");
    }
}
