package com.mamacare.assistant;

import com.mamacare.common.AuthUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/assistant")
@PreAuthorize("hasRole('PATIENT')")
public class AssistantController {
    public record Question(@NotBlank @Size(max = 500) String question) {}

    private final AssistantService service;

    public AssistantController(AssistantService service) {
        this.service = service;
    }

    @PostMapping("/ask")
    public AssistantService.Answer ask(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody Question q) {
        return service.ask(me, q.question());
    }
}
