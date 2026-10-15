package com.mamacare.pregnancy;

import com.mamacare.pregnancy.PregnancyDtos.WeekInfo;

import java.util.ArrayList;
import java.util.List;

/**
 * Static, general-education content for weeks 4-40 (approximate fruit comparisons).
 * This is NOT personalised medical advice; the UI says so and defers to the doctor's schedule.
 */
public final class PregnancyWeekCatalog {
    private PregnancyWeekCatalog() {}

    // week | fruit | approx size | description
    private static final String[] RAW = {
            "4|Poppy seed|2 mm|Implantation is complete and the cells that become the embryo and placenta are forming.",
            "5|Sesame seed|3 mm|The neural tube, which becomes the brain and spinal cord, is forming and the heart tube begins to beat.",
            "6|Lentil|6 mm|Tiny buds that become arms and legs appear, and the heart beats regularly.",
            "7|Blueberry|1.3 cm|Facial features such as the nostrils and the lenses of the eyes start to form.",
            "8|Raspberry|1.6 cm|Fingers and toes begin to take shape and the embryo starts making small movements.",
            "9|Cherry|2.3 cm|The embryo is now called a fetus and the major organs keep developing.",
            "10|Strawberry|3.1 cm|Vital organs have formed and the fetus moves, though you cannot feel it yet.",
            "11|Fig|4.1 cm|Bones begin to harden and the fetus can open and close its fists.",
            "12|Lime|5.4 cm|Reflexes are developing and the kidneys begin producing urine.",
            "13|Peach|7.4 cm|Vocal cords are forming and fingerprints start to develop.",
            "14|Lemon|8.7 cm|The fetus can squint and frown, and the neck is lengthening.",
            "15|Apple|10 cm|Fine hair called lanugo covers the body and bones continue to harden.",
            "16|Avocado|11.6 cm|The eyes can sense light and the nervous system keeps maturing.",
            "17|Pear|13 cm|Fat stores start to build and cartilage is turning into bone.",
            "18|Bell pepper|14 cm|The baby may begin yawning and hiccupping; some parents feel first flutters.",
            "19|Mango|15 cm|A protective coating called vernix caseosa starts covering the skin.",
            "20|Banana|25 cm|Halfway there. The baby swallows amniotic fluid and movements become more noticeable.",
            "21|Carrot|27 cm|Taste buds are developing and the baby moves more regularly.",
            "22|Papaya|28 cm|The senses of touch and hearing are developing.",
            "23|Grapefruit|29 cm|The baby can respond to loud sounds and the lungs keep developing.",
            "24|Corn|30 cm|The face is fully formed and the lungs are developing the branches needed for breathing.",
            "25|Cauliflower|35 cm|The baby has sleep and wake cycles and may respond to your voice.",
            "26|Lettuce|36 cm|The eyes begin to open and the baby practises breathing movements.",
            "27|Rutabaga|37 cm|The brain is very active and the baby may respond to light and sound.",
            "28|Eggplant|38 cm|The third trimester begins. The baby can blink and the lungs continue to mature.",
            "29|Butternut squash|39 cm|Bones are fully formed but still soft, and muscles are getting stronger.",
            "30|Cabbage|40 cm|Steady weight gain continues and the brain is growing rapidly.",
            "31|Coconut|41 cm|All five senses are working and the baby is gaining fat.",
            "32|Jicama|42 cm|Toenails have formed and fat stores help prepare for life outside the womb.",
            "33|Pineapple|44 cm|The immune system is developing and the skull bones stay flexible for birth.",
            "34|Cantaloupe|45 cm|The nervous system and lungs are maturing.",
            "35|Honeydew melon|46 cm|The kidneys are fully developed and the liver can process some waste.",
            "36|Romaine lettuce|47 cm|Most lanugo is shed and the baby may move lower into the pelvis.",
            "37|Swiss chard|49 cm|The baby practises sucking and gripping.",
            "38|Leek|50 cm|Organs are ready for life outside the womb while the brain and lungs keep maturing.",
            "39|Mini watermelon|51 cm|Full term. The brain and lungs are still developing.",
            "40|Pumpkin|51 cm|Your due-date week. Only a small share of babies arrive exactly on the due date."
    };

    private static final List<WeekInfo> WEEKS = build();

    private static List<WeekInfo> build() {
        List<WeekInfo> list = new ArrayList<>();
        for (String line : RAW) {
            String[] p = line.split("\\|");
            int week = Integer.parseInt(p[0]);
            list.add(new WeekInfo(week, trimesterOf(week), p[1], p[2], p[3], milestones(week)));
        }
        return List.copyOf(list);
    }

    public static int trimesterOf(int completedOrCurrentWeek) {
        return completedOrCurrentWeek <= 13 ? 1 : completedOrCurrentWeek <= 27 ? 2 : 3;
    }

    private static List<String> milestones(int w) {
        List<String> m = new ArrayList<>();
        if (w >= 8 && w <= 10) m.add("The first antenatal visit is commonly scheduled around now.");
        if (w >= 11 && w <= 14) m.add("A dating / first-trimester scan and screening are commonly offered around 11-14 weeks.");
        if (w >= 18 && w <= 22) m.add("A detailed anatomy scan is commonly offered around 18-22 weeks.");
        if (w >= 24 && w <= 28) m.add("Glucose screening for gestational diabetes is commonly done around 24-28 weeks.");
        if (w >= 28) m.add("Check-ups usually become more frequent in the third trimester.");
        if (w >= 35 && w <= 37) m.add("Group B strep screening is commonly done around 35-37 weeks.");
        if (w >= 36) m.add("A good time to finalise your birth plan and pack your hospital bag.");
        if (!m.isEmpty()) m.add("Your doctor will advise the schedule that is right for you.");
        return m;
    }

    public static List<WeekInfo> all() {
        return WEEKS;
    }

    /** Clamps to the supported range 4-40. */
    public static WeekInfo forWeek(int week) {
        int w = Math.max(4, Math.min(40, week));
        return WEEKS.get(w - 4);
    }
}
