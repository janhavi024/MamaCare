package com.mamacare.audit;

import com.mamacare.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "audit_logs", indexes = {
        @Index(name = "idx_audit_actor", columnList = "actorId"),
        @Index(name = "idx_audit_created", columnList = "createdAt")})
@Getter
@Setter
@NoArgsConstructor
public class AuditLog extends BaseEntity {
    private Long actorId;

    @Column(nullable = false, length = 60)
    private String action;

    @Column(length = 40)
    private String entityType;

    private Long entityId;

    /** Never put passwords, tokens or medical values here. */
    @Column(length = 300)
    private String details;
}
