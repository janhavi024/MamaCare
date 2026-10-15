package com.mamacare.medicalrecord;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "medical_records", indexes = @Index(name = "idx_record_patient_date", columnList = "patient_id,recordDate"))
@Getter
@Setter
@NoArgsConstructor
public class MedicalRecord extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "uploaded_by", nullable = false)
    private User uploadedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RecordType type;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(length = 4000)
    private String notes;

    @Column(nullable = false)
    private LocalDate recordDate;

    // file metadata (all null when the record is text-only)
    @Column(length = 150)
    private String fileName;

    @Column(length = 100)
    private String contentType;

    private Long sizeBytes;

    /** Random name inside the private storage directory. Never exposed to clients. */
    @Column(length = 80)
    private String storageKey;
}
