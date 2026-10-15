package com.mamacare.assistant;

import com.mamacare.common.AuthUser;
import com.mamacare.pregnancy.PregnancyDtos.ProgressDto;
import com.mamacare.pregnancy.PregnancyService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

/**
 * Rule-based pregnancy INFORMATION assistant. It needs no paid API and no external service.
 * It matches the question against a small, reviewed set of general-education topics, checks for emergency
 * warning phrases first, and never diagnoses or recommends medication.
 * A hosted LLM could be plugged in behind {@link #ask} later without changing the API.
 */
@Service
public class AssistantService {
    public static final String DISCLAIMER = "This is general information, not medical advice or a diagnosis. "
            + "Please talk to your doctor or midwife about anything that concerns you.";

    public record Answer(String answer, boolean urgent, String disclaimer) {}

    private record Topic(List<String> keys, String text) {}

    private static final List<String> URGENT = List.of("heavy bleeding", "bleeding heavily", "soaking a pad", "severe pain",
            "severe abdominal", "no movement", "stopped moving", "not moving", "baby isn't moving", "baby is not moving",
            "seizure", "fit", "blurred vision", "severe headache", "chest pain", "can't breathe", "cannot breathe",
            "water broke", "waters broke", "leaking fluid", "fainted", "high fever", "contractions before");

    private static final List<String> SELF_HARM = List.of("suicide", "kill myself", "self harm", "self-harm", "end my life");

    private static final List<Topic> TOPICS = List.of(
            new Topic(List.of("nausea", "morning sickness", "vomit"),
                    "Nausea is very common, especially in the first trimester. Many people find small, frequent meals, "
                            + "staying hydrated and resting helpful. If you cannot keep fluids down, tell your doctor soon."),
            new Topic(List.of("back pain", "backache"),
                    "Back pain is common as your body changes. Gentle movement, good posture and supportive footwear often help. "
                            + "Mention it to your doctor, especially if it is severe, regular or comes with other symptoms."),
            new Topic(List.of("fatigue", "tired", "exhausted"),
                    "Feeling very tired is common in early and late pregnancy. Rest when you can and keep meals regular. "
                            + "If tiredness is overwhelming, ask your doctor whether any checks are needed."),
            new Topic(List.of("sleep", "insomnia"),
                    "Sleep can be harder as pregnancy progresses. Many people find a regular routine and sleeping on their side "
                            + "with pillows more comfortable. Your doctor can advise on what suits you."),
            new Topic(List.of("heartburn", "acid reflux", "indigestion"),
                    "Heartburn is common later in pregnancy. Smaller meals and avoiding lying down right after eating can help. "
                            + "Ask your doctor or pharmacist before taking anything for it."),
            new Topic(List.of("swelling", "swollen"),
                    "Mild swelling of feet and ankles is common. Sudden swelling of the face or hands, especially with headache or "
                            + "vision changes, needs prompt medical attention."),
            new Topic(List.of("exercise", "workout", "walk", "yoga"),
                    "Gentle activity such as walking is often encouraged in healthy pregnancies, but what is right for you depends "
                            + "on your health. Please check with your doctor before starting or changing exercise."),
            new Topic(List.of("food", "eat", "diet", "nutrition", "avoid"),
                    "A balanced diet with plenty of fruit, vegetables, protein and fluids is generally recommended. Your doctor can "
                            + "tell you about foods to avoid and supplements that are right for you."),
            new Topic(List.of("kick", "movement", "movements"),
                    "Many people first feel movements between about 16 and 25 weeks. Once movements are established, a noticeable "
                            + "change in your baby's usual pattern should be reported to your doctor or hospital the same day."),
            new Topic(List.of("glucose", "diabetes", "sugar test"),
                    "Glucose screening is commonly offered between about 24 and 28 weeks. Your doctor will explain when and how it "
                            + "is done for you."),
            new Topic(List.of("ultrasound", "scan", "anomaly"),
                    "Scans are usually scheduled by your doctor; a dating scan in the first trimester and a detailed anatomy scan "
                            + "around 18-22 weeks are common. Ask your doctor for your personal schedule."),
            new Topic(List.of("medicine", "medication", "tablet", "paracetamol", "ibuprofen", "can i take", "supplement"),
                    "I can't recommend or approve any medicine or supplement. Some are unsafe in pregnancy, so please check with "
                            + "your doctor or pharmacist before taking anything, and only take what has been prescribed for you."),
            new Topic(List.of("anxious", "anxiety", "worried", "stress", "sad", "depress", "mood"),
                    "Many people feel anxious or low during pregnancy. You are not alone, and support is available. Please speak to "
                            + "your doctor or a trusted person about how you feel; the Mood option in Health Monitor can help you track it.")
    );

    private final PregnancyService pregnancy;

    public AssistantService(PregnancyService pregnancy) {
        this.pregnancy = pregnancy;
    }

    public Answer ask(AuthUser me, String question) {
        String q = question.toLowerCase(Locale.ROOT);

        for (String k : SELF_HARM) {
            if (q.contains(k)) {
                return new Answer("I'm really sorry you're feeling this way. Please reach out right now to your local emergency number "
                        + "or a crisis line, and tell someone you trust. If you are in India you can call Tele-MANAS at 14416 or 1-800-891-4416. "
                        + "You deserve immediate support.", true, DISCLAIMER);
            }
        }
        for (String k : URGENT) {
            if (q.contains(k)) {
                return new Answer("What you describe can be a warning sign. Please contact your doctor or maternity unit right away, "
                        + "or go to the nearest emergency department. Do not wait for this app.", true, DISCLAIMER);
            }
        }
        if (q.contains("what week") || q.contains("which week") || q.contains("due date") || q.contains("baby size")
                || q.contains("how big") || q.contains("my week")) {
            ProgressDto p = pregnancy.progress(me, me.id());
            if (p.hasPregnancy()) {
                var w = p.weekInfo();
                return new Answer("You are in week " + p.currentWeek() + " (trimester " + p.trimester() + "), due on " + p.dueDate()
                        + ". Around now your baby is often compared to a " + w.fruit().toLowerCase(Locale.ROOT) + " (about " + w.size()
                        + "). " + w.description(), false, DISCLAIMER);
            }
            return new Answer("I don't see a pregnancy in your profile yet. Add your due date in the Pregnancy Journey screen and I can "
                    + "tell you your week.", false, DISCLAIMER);
        }
        for (Topic t : TOPICS) {
            for (String k : t.keys()) {
                if (q.contains(k)) return new Answer(t.text(), false, DISCLAIMER);
            }
        }
        return new Answer("I can share general information on topics like nausea, back pain, tiredness, sleep, food, exercise, baby movements, "
                + "scans and tests, or tell you which week you are in. I can't diagnose problems or recommend medicines. "
                + "For anything specific to you, please ask your doctor.", false, DISCLAIMER);
    }
}
