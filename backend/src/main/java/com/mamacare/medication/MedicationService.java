package com.mamacare.medication;

import com.mamacare.audit.AuditService;
import com.mamacare.common.AuthUser;
import com.mamacare.exception.BadRequestException;
import com.mamacare.exception.ConflictException;
import com.mamacare.exception.ForbiddenException;
import com.mamacare.exception.ResourceNotFoundException;
import com.mamacare.medication.MedicationDtos.*;
import com.mamacare.patient.PatientAccessService;
import com.mamacare.patient.PatientAccessService.Scope;
import com.mamacare.user.Role;
import com.mamacare.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MedicationService {
    private final MedicationRepository meds;
    private final MedicationReminderRepository reminders;
    private final MedicationIntakeRepository intakes;
    private final UserRepository users;
    private final PatientAccessService access;
    private final AuditService audit;

    public MedicationService(MedicationRepository meds, MedicationReminderRepository reminders, MedicationIntakeRepository intakes,
                             UserRepository users, PatientAccessService access, AuditService audit) {
        this.meds = meds;
        this.reminders = reminders;
        this.intakes = intakes;
        this.users = users;
        this.access = access;
        this.audit = audit;
    }

    @Transactional
    public MedicationDto create(AuthUser actor, Long patientId, MedicationRequest r) {
        access.requireWrite(actor, patientId);
        Medication m = new Medication();
        m.setPatient(users.getReferenceById(patientId));
        if (actor.role() == Role.DOCTOR) m.setPrescribedBy(users.getReferenceById(actor.id()));
        apply(m, r);
        m = meds.save(m);
        // reminders are a personal notification schedule: only the patient creates them
        if (actor.role() == Role.PATIENT && r.reminderTimes() != null) {
            for (String t : new LinkedHashSet<>(r.reminderTimes())) addReminderRow(m, LocalTime.parse(t));
        }
        audit.log(actor.id(), "MEDICATION_CREATED", "Medication", m.getId(), "patientId=" + patientId);
        return toDto(m);
    }

    @Transactional
    public MedicationDto update(AuthUser actor, Long id, MedicationRequest r) {
        Medication m = find(id);
        requireMayEdit(actor, m);
        apply(m, r);
        return toDto(meds.save(m));
    }

    /** Soft delete so dose history is preserved. */
    @Transactional
    public MedicationDto archive(AuthUser actor, Long id) {
        Medication m = find(id);
        requireMayEdit(actor, m);
        m.setActive(false);
        audit.log(actor.id(), "MEDICATION_ARCHIVED", "Medication", m.getId(), null);
        return toDto(meds.save(m));
    }

    @Transactional(readOnly = true)
    public List<MedicationDto> list(AuthUser actor, Long patientId, boolean activeOnly) {
        access.requireRead(actor, patientId, Scope.MEDICATIONS);
        if (!actor.id().equals(patientId)) audit.log(actor.id(), "MEDICATIONS_VIEWED", "Patient", patientId, null);
        List<Medication> list = activeOnly ? meds.findByPatientIdAndActiveTrue(patientId) : meds.findByPatientIdOrderByActiveDescCreatedAtDesc(patientId);
        return toDtos(list);
    }

    // ---- reminders (patient only) ----

    @Transactional
    public ReminderDto addReminder(AuthUser me, Long medId, ReminderRequest r) {
        Medication m = find(medId);
        requirePatientOwner(me, m);
        LocalTime t = LocalTime.parse(r.timeOfDay());
        if (reminders.existsByMedicationIdAndTimeOfDay(medId, t)) throw new ConflictException("A reminder at that time already exists");
        return toDto(addReminderRow(m, t));
    }

    @Transactional
    public ReminderDto toggleReminder(AuthUser me, Long reminderId, boolean enabled) {
        MedicationReminder rem = findReminder(reminderId);
        requirePatientOwner(me, rem.getMedication());
        rem.setEnabled(enabled);
        return toDto(reminders.save(rem));
    }

    @Transactional
    public void deleteReminder(AuthUser me, Long reminderId) {
        MedicationReminder rem = findReminder(reminderId);
        requirePatientOwner(me, rem.getMedication());
        intakes.deleteByReminderId(reminderId);
        reminders.delete(rem);
    }

    /** Today's scheduled doses with taken/not-taken state. {@code date} is the patient's local date, sent by the client. */
    @Transactional(readOnly = true)
    public List<DoseDto> doses(AuthUser actor, Long patientId, LocalDate date) {
        access.requireRead(actor, patientId, Scope.MEDICATIONS);
        LocalDate day = date == null ? LocalDate.now() : date;
        List<Medication> active = meds.findByPatientIdAndActiveTrue(patientId).stream()
                .filter(m -> !m.getStartDate().isAfter(day) && (m.getEndDate() == null || !m.getEndDate().isBefore(day))).toList();
        if (active.isEmpty()) return List.of();
        Map<Long, Medication> byId = active.stream().collect(Collectors.toMap(Medication::getId, m -> m));
        List<MedicationReminder> rems = reminders.findByMedicationIdIn(byId.keySet()).stream().filter(MedicationReminder::isEnabled).toList();
        if (rems.isEmpty()) return List.of();
        Map<Long, MedicationIntake> taken = intakes.findByReminderIdInAndIntakeDate(rems.stream().map(MedicationReminder::getId).toList(), day)
                .stream().collect(Collectors.toMap(i -> i.getReminder().getId(), i -> i));
        return rems.stream().sorted(Comparator.comparing(MedicationReminder::getTimeOfDay)).map(rem -> {
            Medication m = byId.get(rem.getMedication().getId());
            MedicationIntake in = taken.get(rem.getId());
            return new DoseDto(rem.getId(), m.getId(), m.getName(), m.getDosage(), rem.getTimeOfDay().toString(), in != null,
                    in == null ? null : in.getTakenAt());
        }).toList();
    }

    @Transactional
    public DoseDto complete(AuthUser me, Long reminderId, LocalDate date) {
        MedicationReminder rem = findReminder(reminderId);
        requirePatientOwner(me, rem.getMedication());
        LocalDate day = date == null ? LocalDate.now() : date;
        if (day.isAfter(LocalDate.now().plusDays(1))) throw new BadRequestException("Cannot mark a future dose as taken");
        MedicationIntake in = intakes.findByReminderIdAndIntakeDate(reminderId, day).orElseGet(() -> {
            MedicationIntake n = new MedicationIntake();
            n.setReminder(rem);
            n.setIntakeDate(day);
            n.setTakenAt(Instant.now());
            return intakes.save(n);
        });
        Medication m = rem.getMedication();
        return new DoseDto(rem.getId(), m.getId(), m.getName(), m.getDosage(), rem.getTimeOfDay().toString(), true, in.getTakenAt());
    }

    @Transactional
    public DoseDto undoComplete(AuthUser me, Long reminderId, LocalDate date) {
        MedicationReminder rem = findReminder(reminderId);
        requirePatientOwner(me, rem.getMedication());
        LocalDate day = date == null ? LocalDate.now() : date;
        intakes.findByReminderIdAndIntakeDate(reminderId, day).ifPresent(intakes::delete);
        Medication m = rem.getMedication();
        return new DoseDto(rem.getId(), m.getId(), m.getName(), m.getDosage(), rem.getTimeOfDay().toString(), false, null);
    }

    // ---- helpers ----

    private void apply(Medication m, MedicationRequest r) {
        LocalDate start = r.startDate() == null ? LocalDate.now() : r.startDate();
        if (r.endDate() != null && r.endDate().isBefore(start)) throw new BadRequestException("End date cannot be before start date");
        m.setName(r.name().trim());
        m.setDosage(r.dosage().trim());
        m.setFrequency(r.frequency().trim());
        m.setInstructions(r.instructions() == null || r.instructions().isBlank() ? null : r.instructions().trim());
        m.setStartDate(start);
        m.setEndDate(r.endDate());
    }

    private MedicationReminder addReminderRow(Medication m, LocalTime t) {
        MedicationReminder rem = new MedicationReminder();
        rem.setMedication(m);
        rem.setTimeOfDay(t);
        return reminders.save(rem);
    }

    /** Patient may edit only their own self-entered meds; a doctor only meds they prescribed. */
    private void requireMayEdit(AuthUser actor, Medication m) {
        boolean ok = switch (actor.role()) {
            case PATIENT -> m.getPatient().getId().equals(actor.id()) && m.getPrescribedBy() == null;
            case DOCTOR -> m.getPrescribedBy() != null && m.getPrescribedBy().getId().equals(actor.id())
                    && access.isLinkedDoctor(actor.id(), m.getPatient().getId());
            default -> false;
        };
        if (!ok) throw new ForbiddenException("You cannot modify this medication");
    }

    private void requirePatientOwner(AuthUser me, Medication m) {
        if (me.role() != Role.PATIENT || !m.getPatient().getId().equals(me.id())) {
            throw new ForbiddenException("Only the patient can manage their reminders");
        }
    }

    private Medication find(Long id) {
        return meds.findById(id).orElseThrow(() -> new ResourceNotFoundException("Medication not found"));
    }

    private MedicationReminder findReminder(Long id) {
        return reminders.findById(id).orElseThrow(() -> new ResourceNotFoundException("Reminder not found"));
    }

    private MedicationDto toDto(Medication m) {
        return toDtos(List.of(m)).get(0);
    }

    private List<MedicationDto> toDtos(List<Medication> list) {
        if (list.isEmpty()) return List.of();
        Map<Long, List<ReminderDto>> byMed = reminders.findByMedicationIdIn(list.stream().map(Medication::getId).toList()).stream()
                .sorted(Comparator.comparing(MedicationReminder::getTimeOfDay))
                .collect(Collectors.groupingBy(r -> r.getMedication().getId(), Collectors.mapping(this::toDto, Collectors.toList())));
        return list.stream().map(m -> new MedicationDto(m.getId(), m.getPatient().getId(), m.getName(), m.getDosage(), m.getFrequency(),
                m.getInstructions(), m.getStartDate(), m.getEndDate(), m.isActive(),
                m.getPrescribedBy() == null ? null : m.getPrescribedBy().getId(),
                m.getPrescribedBy() == null ? null : m.getPrescribedBy().getFullName(),
                byMed.getOrDefault(m.getId(), List.of()))).toList();
    }

    private ReminderDto toDto(MedicationReminder r) {
        return new ReminderDto(r.getId(), r.getMedication().getId(), r.getTimeOfDay().toString(), r.isEnabled());
    }
}
