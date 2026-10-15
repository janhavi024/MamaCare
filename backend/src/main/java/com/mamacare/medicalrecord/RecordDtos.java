package com.mamacare.medicalrecord;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalDate;

public final class RecordDtos {
    private RecordDtos() {}

    public record RecordRequest(@NotNull RecordType type, @NotBlank @Size(max = 150) String title,
                                @Size(max = 4000) String notes, LocalDate recordDate) {}

    public record RecordDto(Long id, Long patientId, Long uploadedById, String uploadedByName, RecordType type,
                            String title, String notes, LocalDate recordDate, String fileName, String contentType,
                            Long sizeBytes, boolean hasFile, Instant createdAt) {}
}
