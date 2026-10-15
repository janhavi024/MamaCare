package com.mamacare.medication;

import com.mamacare.common.AuthUser;
import com.mamacare.medication.MedicationDtos.*;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api")
public class MedicationController {
    private final MedicationService service;

    public MedicationController(MedicationService service) {
        this.service = service;
    }

    @GetMapping("/patients/{patientId}/medications")
    public List<MedicationDto> list(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId,
                                    @RequestParam(defaultValue = "false") boolean activeOnly) {
        return service.list(me, patientId, activeOnly);
    }

    @PostMapping("/patients/{patientId}/medications")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    @ResponseStatus(HttpStatus.CREATED)
    public MedicationDto create(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId, @Valid @RequestBody MedicationRequest r) {
        return service.create(me, patientId, r);
    }

    @PutMapping("/medications/{id}")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public MedicationDto update(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody MedicationRequest r) {
        return service.update(me, id, r);
    }

    @DeleteMapping("/medications/{id}")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public MedicationDto archive(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        return service.archive(me, id);
    }

    @PostMapping("/medications/{id}/reminders")
    @PreAuthorize("hasRole('PATIENT')")
    @ResponseStatus(HttpStatus.CREATED)
    public ReminderDto addReminder(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody ReminderRequest r) {
        return service.addReminder(me, id, r);
    }

    @PatchMapping("/reminders/{id}")
    @PreAuthorize("hasRole('PATIENT')")
    public ReminderDto toggle(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody ReminderToggle t) {
        return service.toggleReminder(me, id, t.enabled());
    }

    @DeleteMapping("/reminders/{id}")
    @PreAuthorize("hasRole('PATIENT')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteReminder(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        service.deleteReminder(me, id);
    }

    @GetMapping("/patients/{patientId}/medications/today")
    public List<DoseDto> today(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId,
                               @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return service.doses(me, patientId, date);
    }

    @PostMapping("/reminders/{id}/complete")
    @PreAuthorize("hasRole('PATIENT')")
    public DoseDto complete(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @RequestBody(required = false) CompleteRequest r) {
        return service.complete(me, id, r == null ? null : r.date());
    }

    @DeleteMapping("/reminders/{id}/complete")
    @PreAuthorize("hasRole('PATIENT')")
    public DoseDto undo(@AuthenticationPrincipal AuthUser me, @PathVariable Long id,
                        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return service.undoComplete(me, id, date);
    }
}
