package com.mamacare.pregnancy;

import com.mamacare.common.AuthUser;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.pregnancy.PregnancyDtos.*;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class PregnancyController {
    private final PregnancyService service;

    public PregnancyController(PregnancyService service) {
        this.service = service;
    }

    @PostMapping("/patients/me/pregnancy")
    @PreAuthorize("hasRole('PATIENT')")
    @ResponseStatus(HttpStatus.CREATED)
    public PregnancyDto create(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody PregnancyRequest r) {
        return service.create(me, r);
    }

    @PutMapping("/patients/me/pregnancy")
    @PreAuthorize("hasRole('PATIENT')")
    public PregnancyDto update(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody PregnancyRequest r) {
        return service.update(me, r);
    }

    @PostMapping("/patients/me/pregnancy/complete")
    @PreAuthorize("hasRole('PATIENT')")
    public PregnancyDto complete(@AuthenticationPrincipal AuthUser me) {
        return service.complete(me);
    }

    @GetMapping("/patients/{patientId}/pregnancy")
    public PregnancyDto get(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId) {
        return service.get(me, patientId);
    }

    @GetMapping("/patients/{patientId}/pregnancy/progress")
    public ProgressDto progress(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId) {
        return service.progress(me, patientId);
    }

    @PutMapping("/patients/{patientId}/pregnancy/due-date")
    @PreAuthorize("hasRole('DOCTOR')")
    public PregnancyDto confirmDueDate(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId,
                                       @Valid @RequestBody DoctorDueDate r) {
        return service.doctorConfirmDueDate(me, patientId, r.dueDate());
    }

    @GetMapping("/pregnancy/timeline")
    public List<WeekInfo> timeline() {
        return PregnancyWeekCatalog.all();
    }

    @GetMapping("/pregnancy/weeks/{week}")
    public WeekInfo week(@PathVariable int week) {
        if (week < 4 || week > 40) throw new ResourceNotFoundException("Week content is available for weeks 4 to 40");
        return PregnancyWeekCatalog.forWeek(week);
    }
}
