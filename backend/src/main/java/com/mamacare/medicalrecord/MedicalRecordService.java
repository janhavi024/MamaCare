package com.mamacare.medicalrecord;

import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.medicalrecord.RecordDtos.*;
import com.mamacare.patient.PatientAccessService;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.user.UserRepository;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;

@Service
public class MedicalRecordService {
    private final MedicalRecordRepository repo;
    private final UserRepository users;
    private final PatientAccessService access;
    private final FileStorageService storage;
    private final AuditService audit;

    public MedicalRecordService(MedicalRecordRepository repo, UserRepository users, PatientAccessService access,
                                FileStorageService storage, AuditService audit) {
        this.repo = repo;
        this.users = users;
        this.access = access;
        this.storage = storage;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public PageResponse<RecordDto> list(AuthUser actor, Long patientId, Pageable pageable) {
        access.requireRead(actor, patientId, Scope.RECORDS);
        return PageResponse.of(repo.findByPatientId(patientId, pageable), this::toDto);
    }

    @Transactional
    public RecordDto create(AuthUser actor, Long patientId, RecordRequest r) {
        access.requireWrite(actor, patientId);
        MedicalRecord m = new MedicalRecord();
        m.setPatient(users.getReferenceById(patientId));
        m.setUploadedBy(users.getReferenceById(actor.id()));
        m.setType(r.type());
        m.setTitle(r.title().trim());
        m.setNotes(r.notes() == null || r.notes().isBlank() ? null : r.notes().trim());
        m.setRecordDate(r.recordDate() == null ? LocalDate.now() : r.recordDate());
        m = repo.save(m);
        audit.log(actor.id(), "RECORD_CREATED", "MedicalRecord", m.getId(), "patientId=" + patientId);
        return toDto(m);
    }

    @Transactional
    public RecordDto attachFile(AuthUser actor, Long recordId, MultipartFile file) {
        MedicalRecord m = find(recordId);
        requireOwnerOrUploader(actor, m);
        FileStorageService.Stored s = storage.store(file);
        storage.delete(m.getStorageKey());   // replace any previous file
        m.setStorageKey(s.key());
        m.setFileName(s.originalName());
        m.setContentType(s.contentType());
        m.setSizeBytes(s.size());
        audit.log(actor.id(), "RECORD_FILE_UPLOADED", "MedicalRecord", m.getId(), null);
        return toDto(repo.save(m));
    }

    @Transactional(readOnly = true)
    public RecordDto get(AuthUser actor, Long recordId) {
        MedicalRecord m = find(recordId);
        access.requireRead(actor, m.getPatient().getId(), Scope.RECORDS);
        if (!actor.id().equals(m.getPatient().getId())) audit.log(actor.id(), "RECORD_VIEWED", "MedicalRecord", m.getId(), null);
        return toDto(m);
    }

    public record Download(Resource resource, String fileName, String contentType) {}

    @Transactional(readOnly = true)
    public Download download(AuthUser actor, Long recordId) {
        MedicalRecord m = find(recordId);
        access.requireRead(actor, m.getPatient().getId(), Scope.RECORDS);
        if (m.getStorageKey() == null) throw new BadRequestException("This record has no attached file");
        audit.log(actor.id(), "RECORD_DOWNLOADED", "MedicalRecord", m.getId(), null);
        return new Download(storage.load(m.getStorageKey()), m.getFileName(), m.getContentType());
    }

    @Transactional
    public void delete(AuthUser actor, Long recordId) {
        MedicalRecord m = find(recordId);
        requireOwnerOrUploader(actor, m);
        storage.delete(m.getStorageKey());
        repo.delete(m);
        audit.log(actor.id(), "RECORD_DELETED", "MedicalRecord", recordId, null);
    }

    /** Only the patient themself or whoever created the record may change it. */
    private void requireOwnerOrUploader(AuthUser actor, MedicalRecord m) {
        access.requireWrite(actor, m.getPatient().getId());
        boolean isPatient = actor.id().equals(m.getPatient().getId());
        if (!isPatient && !actor.id().equals(m.getUploadedBy().getId())) {
            throw new ForbiddenException("Only the uploader or the patient can modify this record");
        }
    }

    private MedicalRecord find(Long id) {
        return repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Record not found"));
    }

    private RecordDto toDto(MedicalRecord m) {
        return new RecordDto(m.getId(), m.getPatient().getId(), m.getUploadedBy().getId(), m.getUploadedBy().getFullName(),
                m.getType(), m.getTitle(), m.getNotes(), m.getRecordDate(), m.getFileName(), m.getContentType(),
                m.getSizeBytes(), m.getStorageKey() != null, m.getCreatedAt());
    }
}
