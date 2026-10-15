package com.mamacare.doctor;

import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.doctor.DoctorDtos.*;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class DoctorController {
    private final DoctorService service;

    public DoctorController(DoctorService service) {
        this.service = service;
    }

    /** Directory of verified doctors, used when booking appointments or requesting a doctor. */
    @GetMapping("/doctors")
    @PreAuthorize("hasRole('PATIENT')")
    public PageResponse<DoctorSummary> directory(@RequestParam(required = false) String q, Pageable pageable) {
        return service.directory(q, pageable);
    }

    @GetMapping("/doctors/me")
    @PreAuthorize("hasRole('DOCTOR')")
    public DoctorProfileDto me(@AuthenticationPrincipal AuthUser me) {
        return service.myProfile(me);
    }

    @PutMapping("/doctors/me")
    @PreAuthorize("hasRole('DOCTOR')")
    public DoctorProfileDto update(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody UpdateDoctorProfile r) {
        return service.updateProfile(me, r);
    }

    @PostMapping("/doctors/me/verification")
    public DoctorProfileDto submitVerification(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody VerificationSubmit r) {
        return service.submitVerification(me, r);
    }

    @GetMapping("/doctors/me/patients")
    @PreAuthorize("hasRole('DOCTOR')")
    public PageResponse<PatientSummary> patients(@AuthenticationPrincipal AuthUser me, Pageable pageable) {
        return service.myPatients(me, pageable);
    }

    // ---- care links ----

    @PostMapping("/care-links")
    @PreAuthorize("hasRole('PATIENT')")
    @ResponseStatus(HttpStatus.CREATED)
    public LinkDto request(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody LinkRequest r) {
        return service.requestLink(me, r);
    }

    @GetMapping("/care-links")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public PageResponse<LinkDto> links(@AuthenticationPrincipal AuthUser me, @RequestParam(required = false) LinkStatus status,
                                       Pageable pageable) {
        return service.myLinks(me, status, pageable);
    }

    @PatchMapping("/care-links/{id}")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public LinkDto decide(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody LinkDecision d) {
        return service.decide(me, id, d.status());
    }
}
