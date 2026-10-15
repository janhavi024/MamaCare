package com.mamacare.auth;

import com.mamacare.auth.AuthDtos.*;
import com.mamacare.common.AuthUser;
import com.mamacare.user.UserDto;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService service;

    public AuthController(AuthService service) {
        this.service = service;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest r) {
        return service.register(r);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest r) {
        return service.login(r);
    }

    @GetMapping("/me")
    public MeResponse me(@AuthenticationPrincipal AuthUser me) {
        return service.me(me);
    }

    @PutMapping("/me")
    public UserDto update(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody UpdateMeRequest r) {
        return service.updateMe(me, r);
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@AuthenticationPrincipal AuthUser me) {
        service.logout(me);
    }

    @PostMapping("/change-password")
    public AuthResponse changePassword(@AuthenticationPrincipal AuthUser me, @Valid @RequestBody ChangePasswordRequest r) {
        return service.changePassword(me, r);
    }
}
