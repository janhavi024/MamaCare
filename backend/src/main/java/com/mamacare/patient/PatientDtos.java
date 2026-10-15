package com.mamacare.patient;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public final class PatientDtos {
    private PatientDtos() {}

    public record ProfileDto(Long userId, String fullName, String email, String phone, LocalDate dateOfBirth,
                             String bloodGroup, Integer heightCm, String emergencyContactName,
                             String emergencyContactPhone, boolean remindersEnabled) {}

    public record UpdateProfile(@Past LocalDate dateOfBirth,
                                @Pattern(regexp = "^(A|B|AB|O)[+-]$", message = "must be like A+, O-, AB+") String bloodGroup,
                                @Min(100) @Max(250) Integer heightCm,
                                @Size(max = 100) String emergencyContactName,
                                @Pattern(regexp = "^[0-9+\\- ]{6,20}$", message = "invalid phone number") String emergencyContactPhone,
                                Boolean remindersEnabled) {}
}
