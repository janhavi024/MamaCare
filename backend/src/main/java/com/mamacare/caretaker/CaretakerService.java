package com.mamacare.caretaker;

import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;
import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CaretakerService {
    private final CaretakerAccessRepository accessRepo;
    private final UserRepository userRepo;
    private final AuditService audit;

    public CaretakerService(CaretakerAccessRepository accessRepo, UserRepository userRepo, AuditService audit) {
        this.accessRepo = accessRepo;
        this.userRepo = userRepo;
        this.audit = audit;
    }

    /**
     * Caretaker asks a patient for access. Deliberately gives the same outcome whether or not the e-mail belongs
     * to a patient, so the endpoint cannot be used to discover who is registered.
     */
    @Transactional
    public void requestAccess(AuthUser me, String patientEmail) {
        userRepo.findByEmailIgnoreCase(patientEmail.trim())
                .filter(p -> p.getRole() == Role.PATIENT && p.getStatus() == AccountStatus.ACTIVE)
                .ifPresent(patient -> {
                    User caretaker = userRepo.getReferenceById(me.id());
                    CaretakerAccess a = accessRepo.findByPatientIdAndCaretakerId(patient.getId(), me.id())
                            .orElseGet(() -> {
                                CaretakerAccess n = new CaretakerAccess();
                                n.setPatient(patient);
                                n.setCaretaker(caretaker);
                                return n;
                            });
                    if (a.getId() == null || a.getStatus() == AccessStatus.REJECTED || a.getStatus() == AccessStatus.REVOKED) {
                        a.setStatus(AccessStatus.PENDING);
                        a.setCanViewHealth(false);
                        a.setCanViewMedications(false);
                        a.setCanViewAppointments(false);
                        a.setCanViewRecords(false);
                        a = accessRepo.save(a);
                        audit.log(me.id(), "CARETAKER_ACCESS_REQUESTED", "CaretakerAccess", a.getId(), null);
                    }
                });
    }

    @Transactional(readOnly = true)
    public List<CaretakerDtos.AccessDto> forPatient(Long patientId) {
        return accessRepo.findByPatientIdOrderByCreatedAtDesc(patientId).stream().map(CaretakerDtos.AccessDto::from).toList();
    }

    @Transactional(readOnly = true)
    public List<CaretakerDtos.AccessDto> forCaretaker(Long caretakerId) {
        return accessRepo.findByCaretakerIdOrderByCreatedAtDesc(caretakerId).stream().map(CaretakerDtos.AccessDto::from).toList();
    }

    /** Patient-only: grant, reject, edit permissions or revoke. */
    @Transactional
    public CaretakerDtos.AccessDto decide(AuthUser me, Long accessId, CaretakerDtos.AccessDecision d) {
        CaretakerAccess a = accessRepo.findById(accessId).orElseThrow(() -> new ResourceNotFoundException("Access request not found"));
        if (!a.getPatient().getId().equals(me.id())) {
            throw new ForbiddenException("This access request does not belong to you");
        }
        AccessStatus cur = a.getStatus();
        switch (d.status()) {
            case GRANTED -> {
                if (cur != AccessStatus.PENDING && cur != AccessStatus.GRANTED) {
                    throw new BadRequestException("Access was " + cur.name().toLowerCase() + "; the caretaker must send a new request");
                }
                a.setStatus(AccessStatus.GRANTED);
                a.setCanViewHealth(Boolean.TRUE.equals(d.canViewHealth()));
                a.setCanViewMedications(Boolean.TRUE.equals(d.canViewMedications()));
                a.setCanViewAppointments(Boolean.TRUE.equals(d.canViewAppointments()));
                a.setCanViewRecords(Boolean.TRUE.equals(d.canViewRecords()));
            }
            case REJECTED -> {
                if (cur != AccessStatus.PENDING) throw new BadRequestException("Only pending requests can be rejected");
                a.setStatus(AccessStatus.REJECTED);
            }
            case REVOKED -> {
                if (cur != AccessStatus.GRANTED) throw new BadRequestException("Only granted access can be revoked");
                revoke(a);
            }
            default -> throw new BadRequestException("Unsupported status");
        }
        audit.log(me.id(), "CARETAKER_ACCESS_" + a.getStatus(), "CaretakerAccess", a.getId(), null);
        return CaretakerDtos.AccessDto.from(accessRepo.save(a));
    }

    /** Caretaker gives up their own access. */
    @Transactional
    public void leave(AuthUser me, Long accessId) {
        CaretakerAccess a = accessRepo.findById(accessId).orElseThrow(() -> new ResourceNotFoundException("Access not found"));
        if (!a.getCaretaker().getId().equals(me.id())) throw new ForbiddenException("Not your access record");
        revoke(a);
        accessRepo.save(a);
        audit.log(me.id(), "CARETAKER_ACCESS_LEFT", "CaretakerAccess", a.getId(), null);
    }

    private void revoke(CaretakerAccess a) {
        a.setStatus(AccessStatus.REVOKED);
        a.setCanViewHealth(false);
        a.setCanViewMedications(false);
        a.setCanViewAppointments(false);
        a.setCanViewRecords(false);
    }
}
