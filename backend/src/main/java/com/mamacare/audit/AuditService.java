package com.mamacare.audit;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditService {
    private final AuditLogRepository repo;

    public AuditService(AuditLogRepository repo) {
        this.repo = repo;
    }

    /** Own transaction so the audit trail survives if the business transaction rolls back. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void log(Long actorId, String action, String entityType, Long entityId, String details) {
        AuditLog l = new AuditLog();
        l.setActorId(actorId);
        l.setAction(action);
        l.setEntityType(entityType);
        l.setEntityId(entityId);
        l.setDetails(details != null && details.length() > 300 ? details.substring(0, 300) : details);
        repo.save(l);
    }
}
