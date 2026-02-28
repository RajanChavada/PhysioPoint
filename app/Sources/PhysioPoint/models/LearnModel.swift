import Foundation

// MARK: - Learn Body Area

/// Body areas for the Learn / Knowledge Center tab.
/// Separate from BodyArea (used for exercises) because Learn covers areas
/// like "Back & Core" that don't have AR-tracked exercises yet.
enum LearnBodyArea: String, CaseIterable, Identifiable {
    case knee        = "Knee"
    case shoulder    = "Shoulder"
    case backAndCore = "Back & Core"
    case ankleAndFoot = "Ankle & Foot"
    case elbow       = "Elbow"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .knee:         return "ACL, Dislocation, Recovery tips."
        case .shoulder:     return "Shoulder muscles, Pinching pain."
        case .backAndCore:  return "Lower Pain, Posture, Strength."
        case .ankleAndFoot: return "Sprains, Stability, Getting moving."
        case .elbow:        return "Tennis Elbow, Golfer's Elbow."
        }
    }

    /// Custom image name in Resources/
    var imageName: String {
        switch self {
        case .knee:         return "knee-icon"
        case .shoulder:     return "shoulder-icon"
        case .backAndCore:  return "back-icon"
        case .ankleAndFoot: return "ankle-icon"
        case .elbow:        return "elbow-icon"
        }
    }

    /// Fallback SF Symbol when custom image isn't available yet
    var systemImage: String {
        switch self {
        case .knee:         return "figure.run"
        case .shoulder:     return "figure.arms.open"
        case .backAndCore:  return "figure.core.training"
        case .ankleAndFoot: return "figure.step.training"
        case .elbow:        return "figure.hand.raising"
        }
    }

    var conditions: [LearnCondition] {
        switch self {
        case .knee:         return LearnCondition.kneeConditions
        case .shoulder:     return LearnCondition.shoulderConditions
        case .backAndCore:  return LearnCondition.backConditions
        case .ankleAndFoot: return LearnCondition.ankleConditions
        case .elbow:        return LearnCondition.elbowConditions
        }
    }
}

// MARK: - Recovery Phase

struct RecoveryPhase: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let description: String
}

// MARK: - Therapy Technique

struct TherapyTechnique: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
}

// MARK: - Learn Condition

struct LearnCondition: Identifiable {
    let id: UUID
    let name: String
    let shortDescription: String
    let systemIcon: String
    let overview: String
    let recoveryPhases: [RecoveryPhase]
    let techniques: [TherapyTechnique]
    let recommendedExerciseNames: [String]
    let redFlags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        shortDescription: String,
        systemIcon: String,
        overview: String,
        recoveryPhases: [RecoveryPhase],
        techniques: [TherapyTechnique],
        recommendedExerciseNames: [String],
        redFlags: [String]
    ) {
        self.id = id
        self.name = name
        self.shortDescription = shortDescription
        self.systemIcon = systemIcon
        self.overview = overview
        self.recoveryPhases = recoveryPhases
        self.techniques = techniques
        self.recommendedExerciseNames = recommendedExerciseNames
        self.redFlags = redFlags
    }
}

// MARK: - Recovery Essentials

struct RecoveryEssential: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let summary: String
    let tips: [String]
}

extension RecoveryEssential {
    static let all: [RecoveryEssential] = [
        RecoveryEssential(
            title: "Sleep & Recovery",
            icon: "bed.double.fill",
            summary: "Quality sleep accelerates tissue repair and reduces inflammation.",
            tips: [
                "Aim for 7–9 hours of uninterrupted sleep.",
                "Elevate the injured limb with a pillow while sleeping.",
                "Avoid screens 30 minutes before bed to improve sleep quality.",
                "Keep a consistent sleep schedule, even on weekends."
            ]
        ),
        RecoveryEssential(
            title: "Hydration & Nutrition",
            icon: "drop.fill",
            summary: "Proper hydration and nutrition fuel tissue repair and reduce swelling.",
            tips: [
                "Drink at least 8 glasses of water per day.",
                "Increase protein intake to support muscle repair (lean meats, legumes, eggs).",
                "Eat anti-inflammatory foods: berries, fatty fish, leafy greens.",
                "Limit alcohol and caffeine, which can delay healing."
            ]
        ),
        RecoveryEssential(
            title: "Pain Management",
            icon: "waveform.path.ecg",
            summary: "Understanding pain helps you manage it without over-relying on medication.",
            tips: [
                "Use ice for the first 48–72 hours to reduce swelling (20 min on, 20 min off).",
                "Switch to heat therapy after the acute phase to promote blood flow.",
                "Over-the-counter NSAIDs can help, but consult your doctor first.",
                "Gentle movement often reduces pain more than complete rest."
            ]
        ),
        RecoveryEssential(
            title: "Stretching Basics",
            icon: "figure.flexibility",
            summary: "Gentle stretching restores range of motion and prevents stiffness.",
            tips: [
                "Never stretch into sharp pain — mild discomfort is OK.",
                "Hold each stretch for 20–30 seconds, don't bounce.",
                "Stretch after warming up (e.g., after a short walk).",
                "Focus on the muscles around the injured area, not just the injury itself."
            ]
        )
    ]
}

// MARK: - Seed Data

extension LearnCondition {

    // ── ELBOW ──────────────────────────────────────────────────────
    
    static let elbowConditions: [LearnCondition] = [
        LearnCondition(
            name: "Tennis Elbow",
            shortDescription: "Lateral epicondylitis — outer elbow pain from repetitive wrist extension.",
            systemIcon: "figure.tennis",
            overview: """
            Tennis elbow is an overuse injury causing inflammation or microscopic tearing of the tendons \
            that join the forearm muscles on the outside of the elbow. Despite its name, it frequently \
            affects non-athletes who perform repetitive tasks like typing, painting, or using hand tools.\n\n\
            Recovery requires ceasing the aggravating activity, icing, and stretching, followed by \
            eccentric strengthening of the wrist extensors.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Calm the Tendon", duration: "0–2 weeks", description: "Avoid gripping and repetitive wrist movements. Use a brace if needed."),
                RecoveryPhase(title: "Restore Flexibility", duration: "2–4 weeks", description: "Begin gentle wrist flexor and extensor stretches."),
                RecoveryPhase(title: "Eccentric Strengthening", duration: "4–8 weeks", description: "Use light weights to strengthen the tendon while lengthening it."),
                RecoveryPhase(title: "Return to Activity", duration: "2–3 months", description: "Gradually resume normal tasks with improved ergonomics.")
            ],
            techniques: [
                TherapyTechnique(name: "Counterforce Bracing", description: "Applying a strap below the elbow to reduce tension on the injured tendon.", icon: "bandage"),
                TherapyTechnique(name: "Eccentric Exercises", description: "Slowly lowering a weight using the wrist extensors to stimulate healing.", icon: "dumbbell.fill"),
                TherapyTechnique(name: "Ice Massage", description: "Rubbing ice directly over the painful lateral epicondyle for 5 minutes.", icon: "snowflake")
            ],
            recommendedExerciseNames: ["Active Elbow Flexion", "Elbow Flexion & Extension"],
            redFlags: [
                "Elbow is incredibly swollen or deformed",
                "You cannot bend or straighten your elbow at all",
                "Numbness or tingling radiating down into your fingers",
                "Pain preventing basic daily tasks (like opening doors) after weeks of rest"
            ]
        ),
        
        LearnCondition(
            name: "Golfer's Elbow",
            shortDescription: "Medial epicondylitis — inner elbow pain from repetitive wrist flexion.",
            systemIcon: "figure.golf",
            overview: """
            Similar to Tennis Elbow, Golfer's Elbow is tendinopathy on the inside (medial) aspect of the elbow. \
            It is caused by repetitive stress to the tendons that pull your wrist downward (flexion) and twist \
            your forearm inward.\n\n\
            Rehabilitation mirrors tennis elbow but targets the flexor muscles. Early focus is on avoiding \
            heavy lifting or forceful gripping, followed by progressive stretching and strengthening.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Reduce Inflammation", duration: "0–2 weeks", description: "Stop activities causing pain. Use ice and compression."),
                RecoveryPhase(title: "Gentle Stretching", duration: "2–4 weeks", description: "Stretch the forearm by pulling fingers back toward the body."),
                RecoveryPhase(title: "Progressive Loading", duration: "4–8 weeks", description: "Strengthen the wrist flexors with light dumbbells or bands."),
                RecoveryPhase(title: "Activity Reintegration", duration: "8–12 weeks", description: "Return to sports or work with correct form/grip.")
            ],
            techniques: [
                TherapyTechnique(name: "Ergonomic Assessment", description: "Optimizing grip size on tools or rackets to reduce strain.", icon: "hand.raised.fill"),
                TherapyTechnique(name: "Forearm Stretching", description: "Extending the arm and gently stretching the wrist backwards.", icon: "figure.flexibility"),
                TherapyTechnique(name: "Grip Strengthening", description: "Using putty or a stress ball to build forearm endurance.", icon: "hand.point.up.braille.fill")
            ],
            recommendedExerciseNames: ["Active Elbow Flexion", "Elbow Extension Stretch"],
            redFlags: [
                "Sudden sharp pop or tear sensation during lifting",
                "Visible bruising running down the inner forearm",
                "Weakness that causes dropping objects",
                "Tingling specifically in the ring and pinky fingers (Cubital Tunnel sign)"
            ]
        )
    ]

    // ── KNEE ──────────────────────────────────────────────────────

    static let kneeConditions: [LearnCondition] = [
        LearnCondition(
            name: "ACL Tear",
            shortDescription: "Anterior cruciate ligament injury — common in sports with sudden stops and direction changes.",
            systemIcon: "bolt.trianglebadge.exclamationmark.fill",
            overview: """
            The anterior cruciate ligament (ACL) is one of the key ligaments that stabilize your knee joint. \
            ACL tears are among the most common knee injuries, especially in athletes who play sports involving \
            pivoting, jumping, or sudden stops.\n\n\
            Treatment depends on severity. Partial tears may heal with physical therapy alone, while complete \
            tears often require surgical reconstruction followed by 6–12 months of rehabilitation. Early rehab \
            focuses on reducing swelling and restoring range of motion, then progresses to strengthening and \
            eventually sport-specific training.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Rest & Reduce Swelling", duration: "0–2 weeks", description: "Rest, ice, compression, elevation. Protect the knee and let swelling go down."),
                RecoveryPhase(title: "Start Moving Gently", duration: "2–6 weeks", description: "Gentle bending exercises, tighten your thigh muscles, leg raises."),
                RecoveryPhase(title: "Build Strength", duration: "6–16 weeks", description: "Gradually increase effort. Strengthen your hips, thighs, and balance."),
                RecoveryPhase(title: "Back to Normal", duration: "4–12 months", description: "Return to sports and daily life with confidence.")
            ],
            techniques: [
                TherapyTechnique(name: "RICE Method", description: "Rest, Ice, Compression, Elevation — the gold standard for acute injury management.", icon: "snowflake"),
                TherapyTechnique(name: "Quad Sets", description: "Tighten the thigh muscle with the knee straight to maintain quad strength.", icon: "bolt.fill"),
                TherapyTechnique(name: "Balance Training", description: "Single-leg balance exercises to restore proprioception and stability.", icon: "figure.stand")
            ],
            recommendedExerciseNames: ["Straight Leg Raises", "Seated Knee Extension", "Single Leg Balance"],
            redFlags: [
                "Knee gives way or buckles during walking",
                "Significant swelling that doesn't improve after 48 hours",
                "Unable to bear weight on the affected leg",
                "Numbness or tingling below the knee"
            ]
        ),

        LearnCondition(
            name: "Knee Dislocation",
            shortDescription: "Displacement of the kneecap or knee joint — requires careful rehab.",
            systemIcon: "exclamationmark.triangle.fill",
            overview: """
            A knee dislocation occurs when the bones of the knee joint are forced out of alignment. This is a \
            serious injury that can damage ligaments, blood vessels, and nerves. Patellar (kneecap) dislocations \
            are more common and less severe than full knee dislocations.\n\n\
            Recovery focuses on immobilization in the acute phase, followed by progressive range of motion \
            exercises and strengthening. Most people can return to normal activities within 3–6 months with \
            consistent rehabilitation.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Keep Still to Heal", duration: "0–3 weeks", description: "Wear a brace or splint to protect the knee. Ice and keep it raised."),
                RecoveryPhase(title: "Start Moving Gently", duration: "3–6 weeks", description: "Gentle bending and straightening — only within a comfortable range."),
                RecoveryPhase(title: "Build Strength", duration: "6–12 weeks", description: "Gradually strengthen your thigh, hamstring, and hip muscles."),
                RecoveryPhase(title: "Back to Normal", duration: "3–6 months", description: "Return to sports and daily activities with full confidence.")
            ],
            techniques: [
                TherapyTechnique(name: "Patellar Mobilization", description: "Gentle kneecap glides to prevent stiffness and adhesions.", icon: "hand.draw"),
                TherapyTechnique(name: "Cold Therapy", description: "Apply ice packs to reduce swelling and pain after exercises.", icon: "snowflake"),
                TherapyTechnique(name: "Compression Taping", description: "McConnell taping technique to stabilize the kneecap during rehab.", icon: "bandage")
            ],
            recommendedExerciseNames: ["Heel Slides", "Seated Knee Flexion", "Terminal Knee Extension"],
            redFlags: [
                "Sudden increase in swelling after a session",
                "Loss of feeling in the foot or toes",
                "Knee locks in a bent position and won't straighten",
                "Sharp pain behind the knee"
            ]
        ),

        LearnCondition(
            name: "General Knee Pain",
            shortDescription: "Stiffness, soreness, or general discomfort in the knee area.",
            systemIcon: "bandage",
            overview: """
            General knee pain is extremely common and can result from overuse, minor injuries, arthritis, or \
            muscle imbalances. Most cases respond well to gentle exercise, stretching, and activity modification.\n\n\
            The key is to keep the knee moving within a pain-free range. Complete rest often makes stiffness \
            worse. Focus on strengthening the muscles around the knee — especially the quadriceps and hip \
            stabilizers — to take pressure off the joint.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Ease the Pain", duration: "1–2 weeks", description: "Avoid activities that make it worse. Ice after exercise."),
                RecoveryPhase(title: "Start Moving", duration: "2–4 weeks", description: "Begin gentle bending exercises and light walking."),
                RecoveryPhase(title: "Build Strength", duration: "4–8 weeks", description: "Gradually strengthen your thigh and hip muscles."),
                RecoveryPhase(title: "Keep It Up", duration: "Ongoing", description: "Regular exercise to stop the pain coming back.")
            ],
            techniques: [
                TherapyTechnique(name: "Heat Therapy", description: "Apply warmth before exercise to loosen stiff joints and improve blood flow.", icon: "flame"),
                TherapyTechnique(name: "Low-Impact Movement", description: "Swimming, cycling, or walking to keep the joint mobile without high impact.", icon: "figure.walk"),
                TherapyTechnique(name: "Foam Rolling", description: "Self-myofascial release on quads and IT band to reduce tightness.", icon: "cylinder")
            ],
            recommendedExerciseNames: ["Seated Knee Extension", "Straight Leg Raises", "Heel Slides"],
            redFlags: [
                "Pain that wakes you up at night",
                "Sudden onset of redness and warmth around the knee",
                "Inability to fully straighten or bend the knee",
                "Pain persisting beyond 6 weeks despite exercise"
            ]
        )
    ]

    // ── SHOULDER ─────────────────────────────────────────────────

    static let shoulderConditions: [LearnCondition] = [
        LearnCondition(
            name: "Rotator Cuff Injury",
            shortDescription: "Strain or tear of the muscles that stabilize the shoulder.",
            systemIcon: "figure.arms.open",
            overview: """
            The rotator cuff is a group of four muscles and tendons that surround the shoulder joint, keeping \
            the head of the upper arm bone firmly within the shallow socket. Injuries range from mild \
            inflammation (tendinitis) to partial or complete tears.\n\n\
            Most rotator cuff problems respond to physical therapy. Rehab focuses on restoring pain-free \
            range of motion first, then gradually strengthening the rotator cuff and scapular muscles.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Rest & Reduce Pain", duration: "0–2 weeks", description: "Avoid reaching overhead. Ice and gentle swinging exercises."),
                RecoveryPhase(title: "Get Moving Again", duration: "2–6 weeks", description: "Gentle shoulder raising and wall slides."),
                RecoveryPhase(title: "Build Strength", duration: "6–12 weeks", description: "Resistance band exercises for shoulder muscles."),
                RecoveryPhase(title: "Back to Normal", duration: "3–6 months", description: "Return to full overhead reaching and activities.")
            ],
            techniques: [
                TherapyTechnique(name: "Pendulum Exercises", description: "Lean forward and let the arm swing gently in circles to maintain mobility.", icon: "arrow.clockwise"),
                TherapyTechnique(name: "Wall Slides", description: "Slide hands up a wall to improve overhead range of motion safely.", icon: "arrow.up"),
                TherapyTechnique(name: "Resistance Bands", description: "External and internal rotation with bands to strengthen rotator cuff.", icon: "figure.strengthtraining.traditional")
            ],
            recommendedExerciseNames: ["Wall Slides", "Supine Shoulder Flexion", "Standing Shoulder Flexion"],
            redFlags: [
                "Complete inability to lift the arm",
                "Shoulder pain after a fall or direct impact",
                "Persistent night pain that doesn't improve in 2 weeks",
                "Visible deformity of the shoulder"
            ]
        ),

        LearnCondition(
            name: "Shoulder Impingement",
            shortDescription: "Pinching of tendons when lifting the arm overhead.",
            systemIcon: "exclamationmark.triangle",
            overview: """
            Shoulder impingement occurs when the rotator cuff tendons get pinched between the bones of the \
            shoulder during overhead movements. It's common in people who do repetitive overhead activities \
            like swimming, painting, or throwing.\n\n\
            Treatment focuses on correcting posture, strengthening the muscles that pull the shoulder blade \
            down and back, and gradually restoring pain-free overhead reach.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Take It Easy", duration: "0–2 weeks", description: "Avoid reaching overhead. Focus on sitting and standing straighter."),
                RecoveryPhase(title: "Gentle Stretching", duration: "2–4 weeks", description: "Gentle stretching and shoulder blade exercises."),
                RecoveryPhase(title: "Build Strength", duration: "4–8 weeks", description: "Strengthen the shoulder and shoulder blade muscles."),
                RecoveryPhase(title: "Back to Normal", duration: "2–3 months", description: "Gradually return to reaching and lifting overhead.")
            ],
            techniques: [
                TherapyTechnique(name: "Posture Correction", description: "Shoulder blade squeezes and chin tucks to improve upper body posture.", icon: "figure.stand"),
                TherapyTechnique(name: "Scapular Setting", description: "Draw shoulder blades down and back to create space in the joint.", icon: "arrow.down.right"),
                TherapyTechnique(name: "Ice After Activity", description: "Apply ice for 15 minutes after exercise to reduce inflammation.", icon: "snowflake")
            ],
            recommendedExerciseNames: ["Wall Slides", "Standing Shoulder Flexion", "Supine Shoulder Flexion"],
            redFlags: [
                "Sharp catching pain when lowering the arm from overhead",
                "Weakness that makes daily tasks difficult",
                "Pain radiating down the arm past the elbow",
                "Symptoms worsening despite 4 weeks of rehab"
            ]
        )
    ]

    // ── BACK & CORE ──────────────────────────────────────────────

    static let backConditions: [LearnCondition] = [
        LearnCondition(
            name: "Lower Back Pain",
            shortDescription: "The most common musculoskeletal complaint — often from weak core muscles.",
            systemIcon: "figure.core.training",
            overview: """
            Lower back pain affects up to 80% of people at some point in their lives. Most cases are \
            \"non-specific\" — meaning there's no serious underlying cause. Poor posture, weak core muscles, \
            prolonged sitting, and lack of movement are the biggest contributors.\n\n\
            The best evidence-based treatment is staying active. Gentle movement, core strengthening, and \
            hip flexibility work are far more effective than bed rest. Many people see significant improvement \
            within 4–6 weeks of consistent exercise.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Ease Into It", duration: "0–1 week", description: "Gentle walking and basic movement. Don't sit too long."),
                RecoveryPhase(title: "Move More", duration: "1–3 weeks", description: "Walk further each day. Start hip and buttock exercises."),
                RecoveryPhase(title: "Strengthen Your Core", duration: "3–8 weeks", description: "Build up your core muscles with bird dogs, bridges, and planks."),
                RecoveryPhase(title: "Keep It Up", duration: "Ongoing", description: "Regular exercise and sitting awareness to stop the pain coming back.")
            ],
            techniques: [
                TherapyTechnique(name: "Cat-Cow Stretch", description: "Gentle spinal flexion and extension on hands and knees.", icon: "arrow.up.arrow.down"),
                TherapyTechnique(name: "Hip Hinge Training", description: "Learn to bend at the hips instead of rounding the lower back.", icon: "figure.walk"),
                TherapyTechnique(name: "Walking", description: "The simplest and most effective movement for back pain recovery.", icon: "figure.walk")
            ],
            recommendedExerciseNames: ["Hip Hinge", "Standing Hip Flexion"],
            redFlags: [
                "Numbness or tingling in both legs",
                "Loss of bladder or bowel control",
                "Pain after a significant fall or accident",
                "Unexplained weight loss with back pain"
            ]
        ),

        LearnCondition(
            name: "Poor Posture",
            shortDescription: "Rounded shoulders and forward head — leads to neck, back, and shoulder pain.",
            systemIcon: "figure.stand",
            overview: """
            Poor posture — especially the \"tech neck\" position from prolonged phone and computer use — is \
            increasingly common. It places excess strain on the spine, shoulders, and neck muscles.\n\n\
            Improvement comes from strengthening the muscles that pull the shoulders back and down, stretching \
            tight chest muscles, and building awareness of spinal alignment throughout the day.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Notice How You Sit", duration: "Week 1", description: "Set reminders to check your posture every 30 minutes."),
                RecoveryPhase(title: "Start Stretching", duration: "Weeks 1–3", description: "Doorway chest stretches and chin tucks."),
                RecoveryPhase(title: "Build Strength", duration: "Weeks 3–8", description: "Wall slides, rows, and core exercises."),
                RecoveryPhase(title: "Make It a Habit", duration: "Ongoing", description: "Good posture becomes natural with daily practice.")
            ],
            techniques: [
                TherapyTechnique(name: "Chin Tucks", description: "Pull the chin straight back to align the head over the shoulders.", icon: "arrow.backward"),
                TherapyTechnique(name: "Doorway Stretch", description: "Stretch the chest muscles by placing arms on a door frame and leaning forward.", icon: "door.left.hand.open"),
                TherapyTechnique(name: "Desk Ergonomics", description: "Screen at eye level, feet flat, elbows at 90° while typing.", icon: "desktopcomputer")
            ],
            recommendedExerciseNames: ["Wall Slides", "Standing Shoulder Flexion"],
            redFlags: [
                "Sharp neck pain radiating into the arm",
                "Headaches that worsen throughout the day",
                "Tingling or weakness in the hands",
                "Difficulty turning the head to one side"
            ]
        )
    ]

    // ── ANKLE & FOOT ─────────────────────────────────────────────

    static let ankleConditions: [LearnCondition] = [
        LearnCondition(
            name: "Ankle Sprain",
            shortDescription: "Stretched or torn ligaments from rolling the ankle.",
            systemIcon: "figure.step.training",
            overview: """
            Ankle sprains are one of the most common injuries, often occurring during sports, walking on \
            uneven surfaces, or simply stepping wrong. The most common type is a lateral (outside) sprain \
            where the foot rolls inward.\n\n\
            While mild sprains heal in 2–4 weeks, proper rehabilitation is crucial to prevent re-injury. \
            Up to 40% of ankle sprains recur without adequate balance and strength training. Focus on \
            restoring range of motion, then building ankle stability and proprioception.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Rest, Ice & Elevate", duration: "0–3 days", description: "Rest, ice, wrap it up, and keep it raised. Walk carefully."),
                RecoveryPhase(title: "Start Moving Gently", duration: "3–14 days", description: "Gentle ankle circles and tracing the alphabet with your toes."),
                RecoveryPhase(title: "Build Strength", duration: "2–6 weeks", description: "Band exercises, calf raises, and balance practice."),
                RecoveryPhase(title: "Back to Normal", duration: "6–12 weeks", description: "Return to sports and daily activities with confidence.")
            ],
            techniques: [
                TherapyTechnique(name: "RICE Method", description: "Rest, Ice, Compression, Elevation — essential in the first 72 hours.", icon: "snowflake"),
                TherapyTechnique(name: "Ankle Alphabet", description: "Trace the alphabet with your big toe to improve range of motion.", icon: "textformat.abc"),
                TherapyTechnique(name: "Balance Board", description: "Single-leg balance on unstable surfaces to rebuild proprioception.", icon: "figure.stand")
            ],
            recommendedExerciseNames: ["Single Leg Balance", "Standing Hip Flexion"],
            redFlags: [
                "Unable to bear weight after 48 hours",
                "Severe bruising spreading to the toes",
                "Bony tenderness at the ankle bones (possible fracture)",
                "Ankle feels unstable or gives way repeatedly"
            ]
        ),

        LearnCondition(
            name: "Ankle Stiffness",
            shortDescription: "Limited range of motion after injury or prolonged immobilization.",
            systemIcon: "bandage",
            overview: """
            Ankle stiffness commonly occurs after a sprain, fracture, or period of immobilization (e.g., \
            wearing a boot or cast). The ankle joint loses its normal range of motion, which affects \
            walking, squatting, and balance.\n\n\
            Recovery focuses on gentle stretching to restore dorsiflexion (pulling the foot upward), \
            followed by strengthening exercises. Most people regain full mobility within 4–8 weeks of \
            consistent daily stretching and exercise.
            """,
            recoveryPhases: [
                RecoveryPhase(title: "Gentle Stretching", duration: "0–2 weeks", description: "Towel stretches and calf stretches against a wall."),
                RecoveryPhase(title: "Get Moving Again", duration: "2–4 weeks", description: "Ankle circles, heel raises, and rocking exercises."),
                RecoveryPhase(title: "Put Weight On It", duration: "4–6 weeks", description: "Squats to bend the ankle more. Balance practice."),
                RecoveryPhase(title: "Back to Normal", duration: "6–8 weeks", description: "Walking and daily activities without restriction.")
            ],
            techniques: [
                TherapyTechnique(name: "Wall Calf Stretch", description: "Lean into a wall with the stiff ankle behind to stretch the calf and Achilles.", icon: "arrow.forward"),
                TherapyTechnique(name: "Towel Stretch", description: "Sit with leg straight, loop a towel around the ball of the foot and pull gently.", icon: "figure.flexibility"),
                TherapyTechnique(name: "Heel Raises", description: "Rise up on toes and slowly lower to build calf strength and ankle control.", icon: "arrow.up")
            ],
            recommendedExerciseNames: ["Single Leg Balance", "Seated Knee Extension"],
            redFlags: [
                "Sudden increase in swelling after stretching",
                "Sharp pain in the Achilles tendon",
                "Crunching or grinding sensation in the joint",
                "No improvement after 4 weeks of daily stretching"
            ]
        )
    ]
}
