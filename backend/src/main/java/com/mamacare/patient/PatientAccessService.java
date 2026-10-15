package com.mamacare.patient;

import com.mamacare.caretaker.AccessStatus;
import com.mamacare.caretaker.CaretakerAccess;
import com.mamacare.caretaker.CaretakerAccessRepository;
import com.mamacare.common.AuthUser;
import com.mamacare.doctor.DoctorPatientLinkRepository;
import com.mamacare.doctor.LinkStatus;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.user.Role;
import org.springframework.stereotype.Service;

/**
 * Single place that decides who may read or write a patient's data. Every patient-data endpoint calls this with the
 * patient id from the URL; knowing or changing an id is never sufficient on its own.
 * <ul>
 *   <li>PATIENT: only their own data.</li>
 *   <li>DOCTOR: only patients with an ACCEPTED link (doctor must be an ACTIVE, verified account).</li>
 *   <li>CARETAKER: only patients with a GRANTED access row, limited to the permissions the patient ticked.</li>
 *   <li>ADMIN: no access to medical data (least privilege).</li>
 * </ul>
 */
@Service
public class PatientAccessService {
    public enum Scope { PREGNANCY, HEALTH, MEDICATIONS, APPOINTMENTS, RECORDS }

    private final DoctorPatientLinkRepository links;
    private final CaretakerAccessRepository caretakerAccess;

    public PatientAccessService(DoctorPatientLinkRepository links, CaretakerAccessRepository caretakerAccess) {
        this.links = links;
        this.caretakerAccess = caretakerAccess;
    }

    public void requireRead(AuthUser actor, Long patientId, Scope scope) {
        if (!canRead(actor, patientId, scope)) {
            throw new ForbiddenException("You do not have access to this patient's information");
        }
    }

    public boolean canRead(AuthUser actor, Long patientId, Scope scope) {
        if (actor == null || patientId == null) return false;
        return switch (actor.role()) {
            case PATIENT -> actor.id().equals(patientId);
            case DOCTOR -> isLinkedDoctor(actor.id(), patientId);
            case CARETAKER -> caretakerAccess
                    .findByPatientIdAndCaretakerIdAndStatus(patientId, actor.id(), AccessStatus.GRANTED)
                    .map(a -> allows(a, scope)).orElse(false);
            default -> false;
        };
    }

    /** Writes (adding records, prescribing, etc.) are limited to the patient and their linked doctors. */
    public void requireWrite(AuthUser actor, Long patientId) {
        boolean ok = (actor.role() == Role.PATIENT && actor.id().equals(patientId))
                || (actor.role() == Role.DOCTOR && isLinkedDoctor(actor.id(), patientId));
        if (!ok) throw new ForbiddenException("You cannot modify this patient's information");
    }

    public boolean isLinkedDoctor(Long doctorId, Long patientId) {
        return links.existsByDoctorIdAndPatientIdAndStatus(doctorId, patientId, LinkStatus.ACCEPTED);
    }

    private boolean allows(CaretakerAccess a, Scope scope) {
        return switch (scope) {
            case PREGNANCY -> true;   // any granted caretaker can see pregnancy progress
            case HEALTH -> a.isCanViewHealth();
            case MEDICATIONS -> a.isCanViewMedications();
            case APPOINTMENTS -> a.isCanViewAppointments();
            case RECORDS -> a.isCanViewRecords();
        };
    }
}
