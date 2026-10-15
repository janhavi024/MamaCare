package com.mamacare.doctor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalDate;

public final class DoctorDtos {
    private DoctorDtos() {}

    /** Public directory entry: deliberately excludes email, phone and license number. */
    public record DoctorSummary(Long id, String fullName, String specialization, String qualification,
                                String hospital, Integer yearsOfExperience, String bio) {}

    public record DoctorProfileDto(Long id, String fullName, String email, String phone, String specialization,
                                   String qualification, String hospital, String licenseNumber,
                                   Integer yearsOfExperience, String bio, VerificationStatus verificationStatus,
                                   String verificationNotes) {}

    public record UpdateDoctorProfile(@NotBlank @Size(max = 80) String specialization,
                                      @NotBlank @Size(max = 120) String qualification,
                                      @Size(max = 150) String hospital,
                                      @Min(0) @Max(70) Integer yearsOfExperience,
                                      @Size(max = 1000) String bio) {}

    public record VerificationSubmit(@NotBlank @Size(max = 60) String licenseNumber,
                                     @Size(max = 1000) String notes) {}

    public record VerificationDto(Long id, Long doctorId, String doctorName, String doctorEmail,
                                  String specialization, String qualification, String hospital,
                                  String licenseNumber, String submittedNotes, VerificationStatus status,
                                  String reviewNotes, Instant submittedAt, Instant reviewedAt) {}

    public record LinkRequest(@NotNull Long doctorId, @Size(max = 500) String message) {}

    public record LinkDecision(@NotNull LinkStatus status) {}

    public record LinkDto(Long id, Long patientId, String patientName, Long doctorId, String doctorName,
                          LinkStatus status, String message, Instant createdAt) {}

    public record PatientSummary(Long patientId, String fullName, String email, LocalDate dueDate,
                                 Integer gestationalWeek) {}
}
