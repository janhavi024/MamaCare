package com.mamacare.health;

/** Plausibility ranges only (to catch typos). They are NOT clinical thresholds and the app gives no clinical advice. */
public enum ObservationType {
    WEIGHT("kg", 20, 300, false, 0, 0),
    BLOOD_PRESSURE("mmHg", 50, 260, true, 30, 160),   // value = systolic, secondaryValue = diastolic
    HEART_RATE("bpm", 30, 220, false, 0, 0),
    BLOOD_GLUCOSE("mg/dL", 20, 600, false, 0, 0),
    BODY_TEMPERATURE("°C", 34, 43, false, 0, 0),
    URINE_PH("pH", 4.5, 9.0, false, 0, 0),
    SYMPTOM("severity 1-5", 1, 5, false, 0, 0),       // label = symptom name
    MOOD("score 1-5", 1, 5, false, 0, 0);

    public final String unit;
    public final double min;
    public final double max;
    public final boolean hasSecondary;
    public final double secondaryMin;
    public final double secondaryMax;

    ObservationType(String unit, double min, double max, boolean hasSecondary, double secondaryMin, double secondaryMax) {
        this.unit = unit;
        this.min = min;
        this.max = max;
        this.hasSecondary = hasSecondary;
        this.secondaryMin = secondaryMin;
        this.secondaryMax = secondaryMax;
    }
}
