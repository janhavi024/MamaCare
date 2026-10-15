package com.mamacare.doctor;

import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.doctor.DoctorDtos.*;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ConflictException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.pregnancy.PregnancyService;
import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;
import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
public class DoctorService {
    private final DoctorProfileRepository profiles;
    private final DoctorVerificationRepository verifications;
    private final DoctorPatientLinkRepository links;
    private final UserRepository users;
    private final PregnancyService pregnancy;
    private final AuditService audit;

    public DoctorService(DoctorProfileRepository profiles, DoctorVerificationRepository verifications,
                         DoctorPatientLinkRepository links, UserRepository users, PregnancyService pregnancy, AuditService audit) {
        this.profiles = profiles;
        this.verifications = verifications;
        this.links = links;
        this.users = users;
        this.pregnancy = pregnancy;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public PageResponse<DoctorSummary> directory(String q, Pageable pageable) {
        String pattern = "%" + (q == null ? "" : q.trim().toLowerCase()) + "%";
        return PageResponse.of(profiles.searchVerified(pattern, pageable), d -> new DoctorSummary(d.getUser().getId(),
                d.getUser().getFullName(), d.getSpecialization(), d.getQualification(), d.getHospital(),
                d.getYearsOfExperience(), d.getBio()));
    }

    @Transactional(readOnly = true)
    public DoctorProfileDto myProfile(AuthUser me) {
        return toDto(profile(me.id()));
    }

    @Transactional
    public DoctorProfileDto updateProfile(AuthUser me, UpdateDoctorProfile r) {
        DoctorProfile d = profile(me.id());
        d.setSpecialization(r.specialization().trim());
        d.setQualification(r.qualification().trim());
        d.setHospital(r.hospital() == null || r.hospital().isBlank() ? null : r.hospital().trim());
        d.setYearsOfExperience(r.yearsOfExperience());
        d.setBio(r.bio() == null || r.bio().isBlank() ? null : r.bio().trim());
        return toDto(profiles.save(d));
    }

    /** Doctor (re)submits license details. Available while the account is still PENDING/REJECTED. */
    @Transactional
    public DoctorProfileDto submitVerification(AuthUser me, VerificationSubmit r) {
        if (me.role() != Role.DOCTOR) throw new ForbiddenException("Only doctors can submit verification");
        DoctorProfile d = profile(me.id());
        d.setLicenseNumber(r.licenseNumber().trim());
        profiles.save(d);
        DoctorVerification v = verifications.findByDoctorId(me.id()).orElseGet(() -> {
            DoctorVerification n = new DoctorVerification();
            n.setDoctor(users.getReferenceById(me.id()));
            return n;
        });
        if (v.getStatus() == VerificationStatus.APPROVED) throw new ConflictException("Your account is already verified");
        v.setStatus(VerificationStatus.PENDING);
        v.setSubmittedNotes(r.notes());
        v.setReviewNotes(null);
        v.setReviewedAt(null);
        verifications.save(v);
        User u = users.findById(me.id()).orElseThrow();
        if (u.getStatus() == AccountStatus.REJECTED) {
            u.setStatus(AccountStatus.PENDING);
            users.save(u);
        }
        audit.log(me.id(), "DOCTOR_VERIFICATION_SUBMITTED", "DoctorVerification", v.getId(), null);
        return toDto(d);
    }

    // ---- patient <-> doctor links ----

    @Transactional
    public LinkDto requestLink(AuthUser me, LinkRequest r) {
        User doctor = users.findById(r.doctorId()).filter(u -> u.getRole() == Role.DOCTOR && u.getStatus() == AccountStatus.ACTIVE)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found"));
        DoctorPatientLink l = links.findByPatientIdAndDoctorId(me.id(), doctor.getId()).orElse(null);
        if (l != null && (l.getStatus() == LinkStatus.PENDING || l.getStatus() == LinkStatus.ACCEPTED)) {
            throw new ConflictException("You already have a " + l.getStatus().name().toLowerCase() + " request with this doctor");
        }
        if (l == null) {
            l = new DoctorPatientLink();
            l.setPatient(users.getReferenceById(me.id()));
            l.setDoctor(doctor);
        }
        l.setStatus(LinkStatus.PENDING);
        l.setMessage(r.message());
        l.setRespondedAt(null);
        l = links.save(l);
        audit.log(me.id(), "CARE_LINK_REQUESTED", "DoctorPatientLink", l.getId(), "doctorId=" + doctor.getId());
        return toDto(l);
    }

    @Transactional(readOnly = true)
    public PageResponse<LinkDto> myLinks(AuthUser me, LinkStatus status, Pageable pageable) {
        if (me.role() == Role.DOCTOR) {
            var page = status == null ? links.findByDoctorId(me.id(), pageable) : links.findByDoctorIdAndStatus(me.id(), status, pageable);
            return PageResponse.of(page, this::toDto);
        }
        return PageResponse.of(links.findByPatientId(me.id(), pageable), this::toDto);
    }

    @Transactional
    public LinkDto decide(AuthUser me, Long linkId, LinkStatus target) {
        DoctorPatientLink l = links.findById(linkId).orElseThrow(() -> new ResourceNotFoundException("Request not found"));
        boolean isDoctor = me.role() == Role.DOCTOR && l.getDoctor().getId().equals(me.id());
        boolean isPatient = me.role() == Role.PATIENT && l.getPatient().getId().equals(me.id());
        if (!isDoctor && !isPatient) throw new ForbiddenException("This request does not belong to you");
        LinkStatus cur = l.getStatus();
        boolean allowed = switch (target) {
            case ACCEPTED, DECLINED -> isDoctor && cur == LinkStatus.PENDING;
            case REVOKED -> cur == LinkStatus.ACCEPTED || (isPatient && cur == LinkStatus.PENDING);
            default -> false;
        };
        if (!allowed) throw new BadRequestException("Cannot change a " + cur.name().toLowerCase() + " request to " + target.name().toLowerCase());
        l.setStatus(target);
        l.setRespondedAt(Instant.now());
        audit.log(me.id(), "CARE_LINK_" + target, "DoctorPatientLink", l.getId(), null);
        return toDto(links.save(l));
    }

    @Transactional(readOnly = true)
    public PageResponse<PatientSummary> myPatients(AuthUser me, Pageable pageable) {
        return PageResponse.of(links.findByDoctorIdAndStatus(me.id(), LinkStatus.ACCEPTED, pageable), l -> {
            User p = l.getPatient();
            return new PatientSummary(p.getId(), p.getFullName(), p.getEmail(), pregnancy.dueDateFor(p.getId()),
                    pregnancy.completedWeeksFor(p.getId()));
        });
    }

    private DoctorProfile profile(Long userId) {
        return profiles.findByUserId(userId).orElseThrow(() -> new ResourceNotFoundException("Doctor profile not found"));
    }

    private DoctorProfileDto toDto(DoctorProfile d) {
        User u = d.getUser();
        var v = verifications.findByDoctorId(u.getId()).orElse(null);
        return new DoctorProfileDto(u.getId(), u.getFullName(), u.getEmail(), u.getPhone(), d.getSpecialization(),
                d.getQualification(), d.getHospital(), d.getLicenseNumber(), d.getYearsOfExperience(), d.getBio(),
                v == null ? null : v.getStatus(), v == null ? null : v.getReviewNotes());
    }

    private LinkDto toDto(DoctorPatientLink l) {
        return new LinkDto(l.getId(), l.getPatient().getId(), l.getPatient().getFullName(), l.getDoctor().getId(),
                l.getDoctor().getFullName(), l.getStatus(), l.getMessage(), l.getCreatedAt());
    }
}
