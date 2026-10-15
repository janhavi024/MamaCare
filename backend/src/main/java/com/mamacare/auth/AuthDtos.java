package com.mamacare.auth;

import com.mamacare.doctor.VerificationStatus;
import com.mamacare.user.Role;
import com.mamacare.user.UserDto;
import jakarta.validation.constraints.*;

import java.time.Instant;
import java.time.LocalDate;

public final class AuthDtos {
    private AuthDtos() {}

    private static final String PASSWORD_REGEX = "^(?=.*[A-Za-z])(?=.*\\d).{8,72}$";
    private static final String PASSWORD_MSG = "must be 8-72 characters and contain a letter and a number";

    public record RegisterRequest(
            @NotBlank @Size(max = 100) String fullName,
            @NotBlank @Email @Size(max = 150) String email,
            @NotBlank @Pattern(regexp = PASSWORD_REGEX, message = PASSWORD_MSG) String password,
            @NotNull Role role,
            @Pattern(regexp = "^[0-9+\\- ]{6,20}$", message = "invalid phone number") String phone,
            // patient
            LocalDate dueDate,
            // doctor
            @Size(max = 80) String specialization,
            @Size(max = 120) String qualification,
            @Size(max = 150) String hospital,
            @Size(max = 60) String licenseNumber,
            @Min(0) @Max(70) Integer yearsOfExperience,
            @Size(max = 1000) String bio,
            // caretaker
            @Size(max = 60) String relationship) {}

    public record LoginRequest(@NotBlank @Email String email, @NotBlank String password) {}

    public record AuthResponse(String token, Instant expiresAt, UserDto user) {}

    public record MeResponse(UserDto user, VerificationStatus verificationStatus, String verificationNotes) {}

    public record UpdateMeRequest(@NotBlank @Size(max = 100) String fullName,
                                  @Pattern(regexp = "^[0-9+\\- ]{6,20}$", message = "invalid phone number") String phone) {}

    public record ChangePasswordRequest(@NotBlank String currentPassword,
                                        @NotBlank @Pattern(regexp = PASSWORD_REGEX, message = PASSWORD_MSG) String newPassword) {}
}
