package com.mamacare.medicalrecord;

import com.mamacare.common.AuthUser;
import com.mamacare.common.PageResponse;
import com.mamacare.medicalrecord.RecordDtos.*;
import jakarta.validation.Valid;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api")
public class MedicalRecordController {
    private final MedicalRecordService service;

    public MedicalRecordController(MedicalRecordService service) {
        this.service = service;
    }

    @GetMapping("/patients/{patientId}/records")
    public PageResponse<RecordDto> list(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId,
                                        @PageableDefault(size = 30, sort = "recordDate", direction = Sort.Direction.DESC) Pageable pageable) {
        return service.list(me, patientId, pageable);
    }

    @PostMapping("/patients/{patientId}/records")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    @ResponseStatus(HttpStatus.CREATED)
    public RecordDto create(@AuthenticationPrincipal AuthUser me, @PathVariable Long patientId, @Valid @RequestBody RecordRequest r) {
        return service.create(me, patientId, r);
    }

    @GetMapping("/records/{id}")
    public RecordDto get(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        return service.get(me, id);
    }

    @PostMapping(value = "/records/{id}/file", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    public RecordDto upload(@AuthenticationPrincipal AuthUser me, @PathVariable Long id, @RequestParam("file") MultipartFile file) {
        return service.attachFile(me, id, file);
    }

    @GetMapping("/records/{id}/file")
    public ResponseEntity<Resource> download(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        MedicalRecordService.Download d = service.download(me, id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(d.contentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(d.fileName()).build().toString())
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .body(d.resource());
    }

    @DeleteMapping("/records/{id}")
    @PreAuthorize("hasAnyRole('PATIENT','DOCTOR')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal AuthUser me, @PathVariable Long id) {
        service.delete(me, id);
    }
}
