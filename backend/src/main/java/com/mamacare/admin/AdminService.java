package com.mamacare.admin;

import com.mamacare.admin.AdminDtos.*;
import com.mamacare.audit.AuditLog;
import com.mamacare.audit.AuditLogRepository;
import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.doctor.DoctorDtos.VerificationDto;
import com.mamacare.doctor.*;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.user.*;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class AdminService {
    private final UserRepository users;
    private final DoctorVerificationRepository verifications;
    private final DoctorProfileRepository doctorProfiles;
    private final AuditLogRepository auditLogs;
    private final AuditService audit;

    public AdminService(UserRepository users, DoctorVerificationRepository verifications,
                        DoctorProfileRepository doctorProfiles, AuditLogRepository auditLogs, AuditService audit) {
        this.users = users;
        this.verifications = verifications;
        this.doctorProfiles = doctorProfiles;
        this.auditLogs = auditLogs;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public PageResponse<UserDto> listUsers(Role role, AccountStatus status, String q, Pageable pageable) {
        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> ps = new ArrayList<>();
            if (role != null) ps.add(cb.equal(root.get("role"), role));
            if (status != null) ps.add(cb.equal(root.get("status"), status));
            if (q != null && !q.isBlank()) {
                String like = "%" + q.trim().toLowerCase() + "%";
                ps.add(cb.or(cb.like(cb.lower(root.get("fullName")), like), cb.like(cb.lower(root.get("email")), like)));
            }
            return cb.and(ps.toArray(new Predicate[0]));
        };
        return PageResponse.of(users.findAll(spec, pageable), UserDto::from);
    }

    @Transactional
    public UserDto setStatus(AuthUser admin, Long userId, AccountStatus status) {
        User u = users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (u.getId().equals(admin.id())) throw new BadRequestException("You cannot change your own account status");
        if (u.getRole() == Role.ADMIN) throw new ForbiddenException("Administrator accounts cannot be modified here");
        if (status == AccountStatus.ACTIVE && u.getRole() == Role.DOCTOR) {
            var v = verifications.findByDoctorId(u.getId()).orElse(null);
            if (v == null || v.getStatus() != VerificationStatus.APPROVED) {
                throw new BadRequestException("Approve the doctor's verification before activating the account");
            }
        }
        u.setStatus(status);
        if (status == AccountStatus.SUSPENDED) u.setTokenVersion(u.getTokenVersion() + 1);  // kick out active sessions
        audit.log(admin.id(), "ADMIN_SET_STATUS", "User", u.getId(), "status=" + status);
        return UserDto.from(users.save(u));
    }

    @Transactional(readOnly = true)
    public PageResponse<VerificationDto> verifications(VerificationStatus status, Pageable pageable) {
        var page = status == null ? verifications.findAll(pageable) : verifications.findByStatus(status, pageable);
        return PageResponse.of(page, this::toDto);
    }

    @Transactional
    public VerificationDto decide(AuthUser admin, Long verificationId, VerificationDecision d) {
        if (d.decision() == VerificationStatus.PENDING) throw new BadRequestException("Decision must be APPROVED or REJECTED");
        DoctorVerification v = verifications.findById(verificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Verification request not found"));
        User doctor = v.getDoctor();
        v.setStatus(d.decision());
        v.setReviewNotes(d.notes());
        v.setReviewedBy(users.getReferenceById(admin.id()));
        v.setReviewedAt(Instant.now());
        if (doctor.getStatus() != AccountStatus.SUSPENDED) {
            doctor.setStatus(d.decision() == VerificationStatus.APPROVED ? AccountStatus.ACTIVE : AccountStatus.REJECTED);
            users.save(doctor);
        }
        audit.log(admin.id(), "DOCTOR_VERIFICATION_" + d.decision(), "DoctorVerification", v.getId(), "doctorId=" + doctor.getId());
        return toDto(verifications.save(v));
    }

    @Transactional(readOnly = true)
    public Stats stats() {
        long pending = verifications.findByStatus(VerificationStatus.PENDING, PageRequest.of(0, 1)).getTotalElements();
        long pendingAccounts = users.count((root, q, cb) -> cb.equal(root.get("status"), AccountStatus.PENDING));
        return new Stats(users.countByRole(Role.PATIENT), users.countByRole(Role.DOCTOR), users.countByRole(Role.CARETAKER),
                pending, pendingAccounts);
    }

    @Transactional(readOnly = true)
    public PageResponse<AuditDto> auditLogs(Pageable pageable) {
        Pageable sorted = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Sort.by(Sort.Direction.DESC, "createdAt"));
        return PageResponse.of(auditLogs.findAll(sorted), (AuditLog l) -> new AuditDto(l.getId(), l.getActorId(), l.getAction(),
                l.getEntityType(), l.getEntityId(), l.getDetails(), l.getCreatedAt()));
    }

    private VerificationDto toDto(DoctorVerification v) {
        User u = v.getDoctor();
        DoctorProfile p = doctorProfiles.findByUserId(u.getId()).orElse(null);
        return new VerificationDto(v.getId(), u.getId(), u.getFullName(), u.getEmail(),
                p == null ? null : p.getSpecialization(), p == null ? null : p.getQualification(),
                p == null ? null : p.getHospital(), p == null ? null : p.getLicenseNumber(),
                v.getSubmittedNotes(), v.getStatus(), v.getReviewNotes(), v.getCreatedAt(), v.getReviewedAt());
    }
}
