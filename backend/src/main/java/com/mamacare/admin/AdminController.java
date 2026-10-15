package com.mamacare.admin;

import com.mamacare.admin.AdminDtos.*;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.doctor.DoctorDtos.VerificationDto;
import com.mamacare.doctor.VerificationStatus;
import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;
import com.mamacare.user.UserDto;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {
    private final AdminService service;

    public AdminController(AdminService service) {
        this.service = service;
    }

    @GetMapping("/stats")
    public Stats stats() {
        return service.stats();
    }

    @GetMapping("/users")
    public PageResponse<UserDto> users(@RequestParam(required = false) Role role, @RequestParam(required = false) AccountStatus status,
                                       @RequestParam(required = false) String q, Pageable pageable) {
        return service.listUsers(role, status, q, pageable);
    }

    @PatchMapping("/users/{id}/status")
    public UserDto setStatus(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody StatusUpdate r) {
        return service.setStatus(me, id, r.status());
    }

    @GetMapping("/doctor-verifications")
    public PageResponse<VerificationDto> verifications(@RequestParam(required = false) VerificationStatus status, Pageable pageable) {
        return service.verifications(status, pageable);
    }

    @PatchMapping("/doctor-verifications/{id}")
    public VerificationDto decide(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @Valid @RequestBody VerificationDecision d) {
        return service.decide(me, id, d);
    }

    @GetMapping("/audit-logs")
    public PageResponse<AuditDto> audit(Pageable pageable) {
        return service.auditLogs(pageable);
    }
}
