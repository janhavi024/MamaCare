package com.mamacare.auth;

import com.mamacare.audit.AuditService;
import com.mamacare.auth.AuthDtos.*;
import com.mamacare.caretaker.CaretakerProfile;
import com.mamacare.caretaker.CaretakerProfileRepository;
import com.mamacare.common.AuthUser;
import com.mamacare.doctor.*;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ConflictException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.patient.PatientProfile;
import com.mamacare.patient.PatientProfileRepository;
import com.mamacare.pregnancy.PregnancyService;
import com.mamacare.user.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
public class AuthService {
    private final UserRepository users;
    private final PatientProfileRepository patientProfiles;
    private final DoctorProfileRepository doctorProfiles;
    private final DoctorVerificationRepository verifications;
    private final CaretakerProfileRepository caretakerProfiles;
    private final PregnancyService pregnancyService;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final AuditService audit;
    private final boolean requirePatientApproval;
    private final String dummyHash;

    public AuthService(UserRepository users, PatientProfileRepository patientProfiles, DoctorProfileRepository doctorProfiles,
                       DoctorVerificationRepository verifications, CaretakerProfileRepository caretakerProfiles,
                       PregnancyService pregnancyService, PasswordEncoder encoder, JwtService jwt, AuditService audit,
                       @Value("${app.registration.require-patient-approval:false}") boolean requirePatientApproval) {
        this.users = users;
        this.patientProfiles = patientProfiles;
        this.doctorProfiles = doctorProfiles;
        this.verifications = verifications;
        this.caretakerProfiles = caretakerProfiles;
        this.pregnancyService = pregnancyService;
        this.encoder = encoder;
        this.jwt = jwt;
        this.audit = audit;
        this.requirePatientApproval = requirePatientApproval;
        this.dummyHash = encoder.encode("not-a-real-password");
    }

    @Transactional
    public AuthResponse register(RegisterRequest r) {
        if (r.role() == Role.ADMIN) throw new ForbiddenException("Administrator accounts cannot be self-registered");
        String email = r.email().trim().toLowerCase();
        if (users.existsByEmailIgnoreCase(email)) throw new ConflictException("An account with this e-mail already exists");
        if (r.role() == Role.DOCTOR && (isBlank(r.specialization()) || isBlank(r.qualification()) || isBlank(r.licenseNumber()))) {
            throw new BadRequestException("Doctors must provide specialization, qualification and license number");
        }

        User u = new User();
        u.setFullName(r.fullName().trim());
        u.setEmail(email);
        u.setPasswordHash(encoder.encode(r.password()));
        u.setRole(r.role());
        u.setPhone(blankToNull(r.phone()));
        u.setStatus(switch (r.role()) {
            case DOCTOR -> AccountStatus.PENDING;                      // until an admin verifies the license
            case PATIENT -> requirePatientApproval ? AccountStatus.PENDING : AccountStatus.ACTIVE;
            default -> AccountStatus.ACTIVE;
        });
        u = users.save(u);

        switch (r.role()) {
            case PATIENT -> {
                PatientProfile p = new PatientProfile();
                p.setUser(u);
                patientProfiles.save(p);
                if (r.dueDate() != null) pregnancyService.createFor(u, null, r.dueDate(), null);
            }
            case DOCTOR -> {
                DoctorProfile d = new DoctorProfile();
                d.setUser(u);
                d.setSpecialization(r.specialization().trim());
                d.setQualification(r.qualification().trim());
                d.setHospital(blankToNull(r.hospital()));
                d.setLicenseNumber(r.licenseNumber().trim());
                d.setYearsOfExperience(r.yearsOfExperience());
                d.setBio(blankToNull(r.bio()));
                doctorProfiles.save(d);
                DoctorVerification v = new DoctorVerification();
                v.setDoctor(u);
                verifications.save(v);
            }
            case CARETAKER -> {
                CaretakerProfile c = new CaretakerProfile();
                c.setUser(u);
                c.setRelationship(blankToNull(r.relationship()));
                caretakerProfiles.save(c);
            }
            default -> throw new ForbiddenException("Role not allowed");
        }
        audit.log(u.getId(), "REGISTER", "User", u.getId(), "role=" + u.getRole());
        return issue(u);
    }

    @Transactional
    public AuthResponse login(LoginRequest r) {
        User u = users.findByEmailIgnoreCase(r.email().trim()).orElse(null);
        // Always run one BCrypt comparison so response time does not reveal whether the e-mail exists.
        boolean ok = encoder.matches(r.password(), u != null ? u.getPasswordHash() : dummyHash);
        if (u == null || !ok) {
            audit.log(u != null ? u.getId() : null, "LOGIN_FAILED", "User", u != null ? u.getId() : null, null);
            throw new BadCredentialsException("Invalid email or password");
        }
        if (u.getStatus() == AccountStatus.SUSPENDED) {
            audit.log(u.getId(), "LOGIN_BLOCKED_SUSPENDED", "User", u.getId(), null);
            throw new ForbiddenException("This account has been suspended. Please contact support.");
        }
        u.setLastLoginAt(Instant.now());
        audit.log(u.getId(), "LOGIN", "User", u.getId(), null);
        return issue(users.save(u));
    }

    @Transactional(readOnly = true)
    public MeResponse me(AuthUser me) {
        User u = users.findById(me.id()).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        VerificationStatus vs = null;
        String notes = null;
        if (u.getRole() == Role.DOCTOR) {
            var v = verifications.findByDoctorId(u.getId()).orElse(null);
            if (v != null) {
                vs = v.getStatus();
                notes = v.getReviewNotes();
            }
        }
        return new MeResponse(UserDto.from(u), vs, notes);
    }

    @Transactional
    public UserDto updateMe(AuthUser me, UpdateMeRequest r) {
        User u = users.findById(me.id()).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        u.setFullName(r.fullName().trim());
        u.setPhone(blankToNull(r.phone()));
        return UserDto.from(users.save(u));
    }

    /** Invalidates every token issued so far for this user. */
    @Transactional
    public void logout(AuthUser me) {
        User u = users.findById(me.id()).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        u.setTokenVersion(u.getTokenVersion() + 1);
        users.save(u);
        audit.log(me.id(), "LOGOUT", "User", me.id(), null);
    }

    @Transactional
    public AuthResponse changePassword(AuthUser me, ChangePasswordRequest r) {
        User u = users.findById(me.id()).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (!encoder.matches(r.currentPassword(), u.getPasswordHash())) {
            throw new BadRequestException("Current password is incorrect");
        }
        u.setPasswordHash(encoder.encode(r.newPassword()));
        u.setTokenVersion(u.getTokenVersion() + 1);   // sign out other devices
        audit.log(me.id(), "PASSWORD_CHANGED", "User", me.id(), null);
        return issue(users.save(u));
    }

    private AuthResponse issue(User u) {
        Instant exp = jwt.expiryFromNow();
        return new AuthResponse(jwt.generate(u, exp), exp, UserDto.from(u));
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
