package com.mamacare.caretaker;

import com.mamacare.common.AuthUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class CaretakerController {
    private final CaretakerService service;

    public CaretakerController(CaretakerService service) {
        this.service = service;
    }

    @PostMapping("/caretaker/requests")
    @PreAuthorize("hasRole('CARETAKER')")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public Map<String, String> request(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody CaretakerDtos.AccessRequest r) {
        service.requestAccess(me, r.patientEmail());
        return Map.of("message", "If a patient account exists for that e-mail, they have been asked to approve your access.");
    }

    @GetMapping("/caretaker/patients")
    @PreAuthorize("hasRole('CARETAKER')")
    public List<CaretakerDtos.AccessDto> myPatients(@AuthenticationPrincipal AuthUser me) {
        return service.forCaretaker(me.id());
    }

    @DeleteMapping("/caretaker/access/{id}")
    @PreAuthorize("hasRole('CARETAKER')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void leave(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        service.leave(me, id);
    }

    @GetMapping("/patients/me/caretaker-access")
    @PreAuthorize("hasRole('PATIENT')")
    public List<CaretakerDtos.AccessDto> access(@AuthenticationPrincipal AuthUser me) {
        return service.forPatient(me.id());
    }

    @PatchMapping("/caretaker-access/{id}")
    @PreAuthorize("hasRole('PATIENT')")
    public CaretakerDtos.AccessDto decide(@AuthenticationPrincipal AuthUser me, @PathVariable Long id,
                                          @Valid @RequestBody CaretakerDtos.AccessDecision d) {
        return service.decide(me, id, d);
    }
}
