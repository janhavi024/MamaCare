package com.mamacare.doctor;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface DoctorProfileRepository extends JpaRepository<DoctorProfile, Long> {
    Optional<DoctorProfile> findByUserId(Long userId);

    /** Public directory: only ACTIVE (admin-verified) doctors are listed. */
    @Query("select d from DoctorProfile d where d.user.status = com.mamacare.user.AccountStatus.ACTIVE " +
            "and (lower(d.user.fullName) like :pattern or lower(d.specialization) like :pattern)")
    Page<DoctorProfile> searchVerified(@Param("pattern") String pattern, Pageable pageable);
}
