package com.mamacare.pregnancy;

import com.mamacare.pregnancy.PregnancyDtos.ProgressDto;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class PregnancyProgressTest {
    private ProgressDto at(long daysUntilDue) {
        return PregnancyService.progressFor(LocalDate.now().plusDays(daysUntilDue), Pregnancy.DueDateSource.SELF_REPORTED);
    }

    @Test
    void startOfPregnancy() {
        ProgressDto p = at(280);
        assertEquals(0, p.completedWeeks());
        assertEquals(1, p.currentWeek());
        assertEquals(1, p.trimester());
        assertEquals(0.0, p.percentComplete());
    }

    @Test
    void midPregnancy() {
        ProgressDto p = at(140);   // 140 days gone = exactly 20 weeks
        assertEquals(20, p.completedWeeks());
        assertEquals(0, p.daysIntoWeek());
        assertEquals(21, p.currentWeek());
        assertEquals(2, p.trimester());
        assertEquals(20, p.remainingWeeks());
        assertEquals(50.0, p.percentComplete());
    }

    @Test
    void dueDateAndOverdueAreClamped() {
        ProgressDto due = at(0);
        assertEquals(40, due.completedWeeks());
        assertEquals(40, due.currentWeek());
        assertEquals(0, due.remainingWeeks());
        assertEquals(100.0, due.percentComplete());
        ProgressDto late = at(-10);
        assertEquals(0L, late.daysUntilDue());
        assertEquals(40, late.currentWeek());
        assertEquals(3, late.trimester());
    }

    @Test
    void catalogIsClampedAndHasMilestones() {
        assertEquals(4, PregnancyWeekCatalog.forWeek(1).week());
        assertEquals(40, PregnancyWeekCatalog.forWeek(99).week());
        assertEquals(37, PregnancyWeekCatalog.all().size());
        assertFalse(PregnancyWeekCatalog.forWeek(20).milestones().isEmpty());
    }
}
