package com.mamacare.patient;

import com.mamacare.common.AuthUser;
import com.mamacare.patient.PatientDtos.*;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/patients")
public class PatientController {
    private final PatientService service;

    public PatientController(PatientService service) {
        this.service = service;
    }

    @GetMapping("/me/profile")
    @PreAuthorize("hasRole('PATIENT')")
    public ProfileDto myProfile(@AuthenticationPrincipal AuthUser me) {
        return service.get(me, me.id());
    }

    @PutMapping("/me/profile")
    @PreAuthorize("hasRole('PATIENT')")
    public ProfileDto update(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody UpdateProfile r) {
        return service.update(me, r);
    }

    @GetMapping("/{patientId}/profile")
    public ProfileDto profile(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId) {
        return service.get(me, patientId);
    }
}
