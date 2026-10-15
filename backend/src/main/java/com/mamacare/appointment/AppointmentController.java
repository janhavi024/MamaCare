package com.mamacare.appointment;

import com.mamacare.appointment.AppointmentDtos.*;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api")
public class AppointmentController {
    private final AppointmentService service;

    public AppointmentController(AppointmentService service) {
        this.service = service;
    }

    @GetMapping("/appointments")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public PageResponse<AppointmentDto> list(@AuthenticationPrincipal AuthUser me, @RequestParam(required = false) AppointmentStatus status,
                                             @RequestParam(required = false) Instant from,
                                             @PageableDefault(size = 30, sort = "scheduledAt", direction = Sort.Direction.ASC) Pageable pageable) {
        return service.list(me, status, from, pageable);
    }

    @PostMapping("/appointments")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    @ResponseStatus(HttpStatus.CREATED)
    public AppointmentDto create(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody BookRequest r) {
        return service.create(me, r);
    }

    @GetMapping("/appointments/{id}")
    public AppointmentDto get(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        return service.get(me, id);
    }

    @PatchMapping("/appointments/{id}/status")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public AppointmentDto status(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody StatusUpdate u) {
        return service.updateStatus(me, id, u);
    }

    @GetMapping("/patients/{patientId}/appointments")
    public PageResponse<AppointmentDto> forPatient(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId,
                                                   @RequestParam(required = false) Instant from,
                                                   @PageableDefault(size = 30, sort = "scheduledAt", direction = Sort.Direction.ASC) Pageable pageable) {
        return service.forPatient(me, patientId, from, pageable);
    }
}
