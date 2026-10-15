package com.mamacare.health;

import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.health.HealthDtos.*;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api")
public class HealthController {
    private final HealthService service;

    public HealthController(HealthService service) {
        this.service = service;
    }

    @PostMapping("/patients/me/health-observations")
    @PreAuthorize("hasRole('PATIENT')")
    @ResponseStatus(HttpStatus.CREATED)
    public ObservationDto record(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody ObservationRequest r) {
        return service.record(me, r);
    }

    @GetMapping("/patients/{patientId}/health-observations")
    public PageResponse<ObservationDto> list(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId,
                                             @RequestParam(required = false) ObservationType type,
                                             @RequestParam(required = false) Instant from, @RequestParam(required = false) Instant to,
                                             @PageableDefault(size = 30, sort = "observedAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return service.list(me, patientId, type, from, to, pageable);
    }

    @GetMapping("/patients/{patientId}/health-observations/latest")
    public List<ObservationDto> latest(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId) {
        return service.latest(me, patientId);
    }

    @DeleteMapping("/patients/me/health-observations/{id}")
    @PreAuthorize("hasRole('PATIENT')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        service.delete(me, id);
    }
}
