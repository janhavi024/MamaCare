package com.mamacare.patient;

import com.mamacare.common.AuthUser;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.patient.PatientDtos.*;
import com.mamacare.user.Role;
import com.mamacare.user.User;
import com.mamacare.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PatientService {
    private final PatientProfileRepository profiles;
    private final UserRepository users;
    private final PatientAccessService access;

    public PatientService(PatientProfileRepository profiles, UserRepository users, PatientAccessService access) {
        this.profiles = profiles;
        this.users = users;
        this.access = access;
    }

    @Transactional(readOnly = true)
    public ProfileDto get(AuthUser actor, Long patientId) {
        access.requireRead(actor, patientId, Scope.PREGNANCY);
        ProfileDto full = toDto(load(patientId));
        // Caretakers only see a minimal profile (no contact details, no date of birth)
        if (actor.role() == Role.CARETAKER) {
            return new ProfileDto(full.userId(), full.fullName(), null, null, null, null, null, null, null, full.remindersEnabled());
        }
        return full;
    }

    @Transactional
    public ProfileDto update(AuthUser me, UpdateProfile r) {
        PatientProfile p = load(me.id());
        p.setDateOfBirth(r.dateOfBirth());
        p.setBloodGroup(r.bloodGroup());
        p.setHeightCm(r.heightCm());
        p.setEmergencyContactName(blank(r.emergencyContactName()));
        p.setEmergencyContactPhone(blank(r.emergencyContactPhone()));
        if (r.remindersEnabled() != null) p.setRemindersEnabled(r.remindersEnabled());
        return toDto(profiles.save(p));
    }

    private PatientProfile load(Long userId) {
        return profiles.findByUserId(userId).orElseThrow(() -> new ResourceNotFoundException("Patient profile not found"));
    }

    private ProfileDto toDto(PatientProfile p) {
        User u = p.getUser();
        return new ProfileDto(u.getId(), u.getFullName(), u.getEmail(), u.getPhone(), p.getDateOfBirth(), p.getBloodGroup(),
                p.getHeightCm(), p.getEmergencyContactName(), p.getEmergencyContactPhone(), p.isRemindersEnabled());
    }

    private static String blank(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
