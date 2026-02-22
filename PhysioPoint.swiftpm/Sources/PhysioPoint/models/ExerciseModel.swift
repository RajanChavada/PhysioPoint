import Foundation

// MARK: - Body Area

enum BodyArea: String, CaseIterable, Identifiable, Codable {
    case knee = "Knee"
    case shoulder = "Shoulder"
    case elbow = "Elbow"
    case ankle = "Ankle"
    case hip = "Hip"
    var id: String { rawValue }
}

// MARK: - Exercise Step

struct ExerciseStep: Identifiable, Hashable {
    let id: UUID
    let stepNumber: Int
    let title: String
    let instruction: String
    let imageName: String?

    init(id: UUID = UUID(), stepNumber: Int, title: String, instruction: String, imageName: String? = nil) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.instruction = instruction
        self.imageName = imageName
    }
}

// MARK: - Exercise

struct Exercise: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bodyArea: BodyArea
    let visualDescription: String
    let targetAngleRange: ClosedRange<Double>   // AR angle math reads this
    let holdSeconds: Int
    let reps: Int
    let steps: [ExerciseStep]
    let caregiverTip: String?
    let thumbnailName: String?

    init(
        id: UUID = UUID(),
        name: String,
        bodyArea: BodyArea = .knee,
        visualDescription: String,
        targetAngleRange: ClosedRange<Double>,
        holdSeconds: Int,
        reps: Int,
        steps: [ExerciseStep] = [],
        caregiverTip: String? = nil,
        thumbnailName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bodyArea = bodyArea
        self.visualDescription = visualDescription
        self.targetAngleRange = targetAngleRange
        self.holdSeconds = holdSeconds
        self.reps = reps
        self.steps = steps
        self.caregiverTip = caregiverTip
        self.thumbnailName = thumbnailName
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: ── KNEE (9 exercises) ──────────────────────────────────
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Exercise {

    // — General Pain —

    static let quadSets = Exercise(
        name: "Quad Sets", bodyArea: .knee,
        visualDescription: "Tighten the thigh muscle, pressing the back of the knee toward the floor.",
        targetAngleRange: 170...180, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie flat", instruction: "Lie on your back with the affected leg straight."),
            ExerciseStep(stepNumber: 2, title: "Tighten", instruction: "Tighten your thigh, pressing the back of your knee down."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds, then relax. Repeat 10 times."),
        ],
        caregiverTip: "Place your hand under the knee — you should feel it press down when the quads engage."
    )

    static let shortArcQuads = Exercise(
        name: "Short Arc Quads", bodyArea: .knee,
        visualDescription: "Lie flat with a rolled towel under the knee. Straighten the leg fully, hold, then lower.",
        targetAngleRange: 170...180, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Lie flat. Place a rolled towel under the knee."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Straighten the lower leg, lifting the foot off the surface."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 5 seconds, then slowly lower. Repeat 10 times."),
        ],
        caregiverTip: "Ensure the towel stays still. Only the lower leg moves."
    )

    static let seatedKneeExtension = Exercise(
        name: "Seated Knee Extension", bodyArea: .knee,
        visualDescription: "Sit on a chair. Straighten the knee fully, hold, then lower.",
        targetAngleRange: 165...180, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit upright", instruction: "Sit on a sturdy chair, feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Extend", instruction: "Straighten your affected leg out in front of you."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds at full extension, then slowly lower."),
        ],
        caregiverTip: "Watch for knee locking. A straight but not hyper-extended position is ideal."
    )

    // — Dislocation Therapy —

    static let straightLegRaises = Exercise(
        name: "Straight Leg Raises", bodyArea: .knee,
        visualDescription: "Lie on your back, keep the leg straight, tighten thigh, lift ~30 cm.",
        targetAngleRange: 160...180, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Lie flat. Bend the uninvolved knee for support."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Tighten thigh, lift the straight leg about 30 cm. Hold 3 sec."),
        ],
        caregiverTip: "Watch that the knee stays locked straight. If it bends, the quads aren't engaging enough."
    )

    static let heelSlides = Exercise(
        name: "Heel Slides", bodyArea: .knee,
        visualDescription: "Lie on your back. Slide your heel toward your glutes, bending the knee. Hold, then straighten.",
        targetAngleRange: 80...100, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Lie flat on your back with legs straight."),
            ExerciseStep(stepNumber: 2, title: "Slide", instruction: "Slowly bend your knee, sliding heel toward glutes."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 3 seconds, then slowly return."),
        ],
        caregiverTip: "Gently guide the heel if they struggle. Do not force past the pain point."
    )

    static let terminalKneeExtension = Exercise(
        name: "Terminal Knee Extension", bodyArea: .knee,
        visualDescription: "Stand with a resistance band behind the knee. Push the knee to full extension against the band.",
        targetAngleRange: 170...180, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Loop a band behind the knee at knee height."),
            ExerciseStep(stepNumber: 2, title: "Extend", instruction: "Push the knee to full extension against resistance."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 3 seconds, then slowly release."),
        ],
        caregiverTip: "Rebuilds the VMO. Ensure the knee tracks over the second toe."
    )

    // — Pain Bending —

    // heelSlides reused from Dislocation Therapy

    static let seatedKneeFlexion = Exercise(
        name: "Seated Knee Flexion", bodyArea: .knee,
        visualDescription: "Sit on a chair. Slide your foot back under the seat to bend the knee.",
        targetAngleRange: 90...115, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", instruction: "Sit upright, slide your foot back under the chair."),
            ExerciseStep(stepNumber: 2, title: "Hold", instruction: "Hold 3 seconds at max bend, then return."),
        ],
        caregiverTip: "Place a towel under the foot to reduce friction."
    )

    static let proneKneeFlexion = Exercise(
        name: "Prone Knee Flexion", bodyArea: .knee,
        visualDescription: "Lie face-down. Bend the knee, bringing the heel toward your glutes.",
        targetAngleRange: 90...120, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie face-down", instruction: "Lie prone with legs straight."),
            ExerciseStep(stepNumber: 2, title: "Bend", instruction: "Slowly bend the knee, bringing heel toward glutes."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 3 seconds. You can gently assist with a towel."),
        ],
        caregiverTip: "Gently assist the heel upward — never force past pain."
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: ── ELBOW (9 exercises) ─────────────────────────────────
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Exercise {

    // — General Pain —

    static let elbowFlexionExtension = Exercise(
        name: "Elbow Flexion & Extension", bodyArea: .elbow,
        visualDescription: "Slowly bend and straighten your elbow through full range of motion.",
        targetAngleRange: 10...130, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Stand with arm at your side, palm forward."),
            ExerciseStep(stepNumber: 2, title: "Bend", instruction: "Slowly bend elbow, hand toward shoulder."),
            ExerciseStep(stepNumber: 3, title: "Extend", instruction: "Slowly straighten back to start."),
        ],
        caregiverTip: "Support the upper arm if needed. Ensure smooth movement."
    )

    static let wristFlexorStretch = Exercise(
        name: "Wrist Flexor Stretch", bodyArea: .elbow,
        visualDescription: "Extend your arm, palm up. Use the other hand to gently pull fingers back.",
        targetAngleRange: 160...180, holdSeconds: 15, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Extend", instruction: "Hold the affected arm straight out, palm up."),
            ExerciseStep(stepNumber: 2, title: "Pull", instruction: "Use the other hand to gently pull fingers toward you."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 15 seconds. You should feel a gentle stretch."),
        ],
        caregiverTip: "Gentle pull only. Stop if tingling or sharp pain occurs."
    )

    static let towelSqueeze = Exercise(
        name: "Towel Squeeze", bodyArea: .elbow,
        visualDescription: "Roll up a small towel. Squeeze it as hard as comfortable for 5 seconds.",
        targetAngleRange: 80...100, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Prepare", instruction: "Roll a hand towel into a tight cylinder."),
            ExerciseStep(stepNumber: 2, title: "Squeeze", instruction: "Grip the towel and squeeze hard for 5 seconds."),
            ExerciseStep(stepNumber: 3, title: "Release", instruction: "Relax fully, then repeat."),
        ],
        caregiverTip: "Forearm muscles should engage visibly. Rebuilds grip strength."
    )

    // — Dislocation Therapy —

    static let activeElbowFlexion = Exercise(
        name: "Active Elbow Flexion", bodyArea: .elbow,
        visualDescription: "Slowly bend the elbow under your own power, aiming for full flexion.",
        targetAngleRange: 30...90, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Arm at side, palm facing forward."),
            ExerciseStep(stepNumber: 2, title: "Bend", instruction: "Slowly bend the elbow as far as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds, then slowly lower."),
        ],
        caregiverTip: "After dislocation, watch for hesitation near 90°. Encourage slow movement."
    )

    static let forearmRotation = Exercise(
        name: "Forearm Rotation", bodyArea: .elbow,
        visualDescription: "Elbow bent 90°, rotate the forearm palm-up then palm-down.",
        targetAngleRange: 80...100, holdSeconds: 2, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Position", instruction: "Bend elbow 90°, tuck it at your side."),
            ExerciseStep(stepNumber: 2, title: "Rotate", instruction: "Turn palm up (supination), then palm down (pronation)."),
            ExerciseStep(stepNumber: 3, title: "Repeat", instruction: "Alternate slowly for 10 reps each direction."),
        ],
        caregiverTip: "Keep elbow tucked at the side — don't let the upper arm swing."
    )

    static let gravityElbowExtension = Exercise(
        name: "Gravity-Assisted Extension", bodyArea: .elbow,
        visualDescription: "Hang your arm over the edge of a table. Let gravity straighten the elbow.",
        targetAngleRange: 160...180, holdSeconds: 30, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit at a table. Hang the forearm off the edge."),
            ExerciseStep(stepNumber: 2, title: "Relax", instruction: "Let gravity pull the forearm down to straighten."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 30 seconds. Do not push or force."),
        ],
        caregiverTip: "Gravity does the work. Muscle tension blocks the stretch."
    )

    // — Pain Bending —

    // elbowFlexionExtension reused from General Pain

    static let elbowExtensionStretch = Exercise(
        name: "Elbow Extension Stretch", bodyArea: .elbow,
        visualDescription: "Place the hand on a table, arm straight. Apply gentle downward pressure on the elbow.",
        targetAngleRange: 165...180, holdSeconds: 15, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Place palm flat on a table at arm's length."),
            ExerciseStep(stepNumber: 2, title: "Press", instruction: "With the other hand, apply gentle pressure on the elbow."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 15 seconds. A gentle sustained stretch."),
        ],
        caregiverTip: "Gentle, sustained pressure — not a quick push. Restores terminal extension."
    )

    // forearmRotation reused from Dislocation Therapy
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: ── HIP / BACK (9 exercises) ────────────────────────────
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Exercise {

    // — General Pain —

    static let clamshells = Exercise(
        name: "Clamshells", bodyArea: .hip,
        visualDescription: "Lie on your side, knees bent. Keep feet together and lift the top knee like a clamshell.",
        targetAngleRange: 30...50, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Lie on unaffected side, knees bent 45°, feet together."),
            ExerciseStep(stepNumber: 2, title: "Open", instruction: "Lift the top knee as high as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 3 seconds, then slowly lower."),
        ],
        caregiverTip: "Hand on the hip to ensure they don't roll backward. Only the knee moves."
    )

    static let gluteBridges = Exercise(
        name: "Glute Bridges", bodyArea: .hip,
        visualDescription: "Lie on your back, knees bent. Lift hips off the floor by squeezing glutes.",
        targetAngleRange: 160...180, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Lie on your back, knees bent, feet flat on floor."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Squeeze glutes and lift hips until body forms a straight line."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 5 seconds. Slowly lower."),
        ],
        caregiverTip: "Hand at the lower back to confirm lift. No excessive arching."
    )

    static let hipFlexorStretch = Exercise(
        name: "Hip Flexor Stretch", bodyArea: .hip,
        visualDescription: "Kneel on the affected side. Lunge forward until you feel a stretch in the front of the hip.",
        targetAngleRange: 160...180, holdSeconds: 20, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Kneel", instruction: "Kneel on the affected leg, other foot forward."),
            ExerciseStep(stepNumber: 2, title: "Lunge", instruction: "Shift weight forward until a stretch is felt."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 20 seconds. Keep torso upright."),
        ],
        caregiverTip: "Support hands if balance is an issue. Avoid excessive pelvic tilt."
    )

    // — Trouble Twisting —

    static let seatedHipRotation = Exercise(
        name: "Seated Hip Rotation", bodyArea: .hip,
        visualDescription: "Sit upright. Cross one ankle over the opposite knee and gently lean forward.",
        targetAngleRange: 70...100, holdSeconds: 15, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", instruction: "Sit upright on a sturdy chair."),
            ExerciseStep(stepNumber: 2, title: "Cross", instruction: "Cross the affected ankle over the opposite knee."),
            ExerciseStep(stepNumber: 3, title: "Lean", instruction: "Lean forward gently. Hold 15 seconds."),
        ],
        caregiverTip: "Staying upright deepens the stretch safely."
    )

    static let supineHipRotation = Exercise(
        name: "Supine Hip Rotation", bodyArea: .hip,
        visualDescription: "Lie on your back, knees bent. Let both knees drop gently to one side.",
        targetAngleRange: 60...90, holdSeconds: 15, reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie flat", instruction: "Lie on your back, both knees bent."),
            ExerciseStep(stepNumber: 2, title: "Drop", instruction: "Let both knees fall gently to one side."),
            ExerciseStep(stepNumber: 3, title: "Return & repeat", instruction: "Return to center, repeat to the other side."),
        ],
        caregiverTip: "Keep shoulders flat. Comfortable rotation, not a strain."
    )

    static let catCow = Exercise(
        name: "Cat-Cow Stretch", bodyArea: .hip,
        visualDescription: "On hands and knees, alternate between arching and rounding the back.",
        targetAngleRange: 150...180, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Hands and knees, spine neutral."),
            ExerciseStep(stepNumber: 2, title: "Cat", instruction: "Round the back up, tucking chin to chest."),
            ExerciseStep(stepNumber: 3, title: "Cow", instruction: "Arch the back, lifting head and tailbone."),
        ],
        caregiverTip: "Slow and rhythmic. Ideal for morning stiffness."
    )

    // — Pain in Bending —

    static let hipHinge = Exercise(
        name: "Hip Hinge", bodyArea: .hip,
        visualDescription: "Stand with feet hip-width. Push hips back while keeping a neutral spine.",
        targetAngleRange: 80...110, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Feet hip-width, slight knee bend."),
            ExerciseStep(stepNumber: 2, title: "Hinge", instruction: "Push hips back, lowering torso. Keep spine neutral."),
            ExerciseStep(stepNumber: 3, title: "Return", instruction: "Squeeze glutes to return to standing."),
        ],
        caregiverTip: "Hand on the lower back to ensure it stays neutral. Foundation for safe bending."
    )

    static let standingHipFlexion = Exercise(
        name: "Standing Hip Flexion", bodyArea: .hip,
        visualDescription: "Stand and lift one knee toward the chest, hold, then lower.",
        targetAngleRange: 80...110, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Stand near a wall for balance."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Lift the affected knee toward your chest."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds, then lower slowly."),
        ],
        caregiverTip: "Slight forward lean is fine. Don't lean backward."
    )

    static let pelvicTilt = Exercise(
        name: "Pelvic Tilt", bodyArea: .hip,
        visualDescription: "Lie on your back, knees bent. Flatten your lower back against the floor.",
        targetAngleRange: 160...180, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie flat", instruction: "Lie on your back, knees bent, feet flat."),
            ExerciseStep(stepNumber: 2, title: "Tilt", instruction: "Tighten abs, pressing lower back into the floor."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds, then relax."),
        ],
        caregiverTip: "You should barely be able to slide a hand under the back at rest — the tilt removes that gap."
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: ── ANKLE (9 exercises) ─────────────────────────────────
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Exercise {

    // — General Pain —

    static let ankleAlphabet = Exercise(
        name: "Ankle Alphabet", bodyArea: .ankle,
        visualDescription: "Sit with leg elevated. Use your foot to trace letters A–Z in the air.",
        targetAngleRange: 0...45, holdSeconds: 0, reps: 1,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit with affected leg elevated on a pillow."),
            ExerciseStep(stepNumber: 2, title: "Trace", instruction: "Use your big toe to write A through Z in the air."),
            ExerciseStep(stepNumber: 3, title: "Rest", instruction: "Rest 30 seconds, then repeat if comfortable."),
        ],
        caregiverTip: "Encourage full movement. Call out letters to make it fun."
    )

    static let ankleCircles = Exercise(
        name: "Ankle Circles", bodyArea: .ankle,
        visualDescription: "Sit or lie down. Rotate the ankle in circles — clockwise then counter-clockwise.",
        targetAngleRange: 0...40, holdSeconds: 0, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Position", instruction: "Sit with the foot slightly off the ground."),
            ExerciseStep(stepNumber: 2, title: "Circle", instruction: "Rotate the ankle clockwise 10 times."),
            ExerciseStep(stepNumber: 3, title: "Reverse", instruction: "Then 10 circles counter-clockwise."),
        ],
        caregiverTip: "Full range in each direction. Hesitation shows where stiffness lives."
    )

    static let seatedCalfRaises = Exercise(
        name: "Seated Calf Raises", bodyArea: .ankle,
        visualDescription: "Sit with feet flat. Push up onto the balls of your feet, then lower.",
        targetAngleRange: 100...130, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", instruction: "Sit with feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Raise", instruction: "Push up onto the balls of your feet."),
            ExerciseStep(stepNumber: 3, title: "Lower", instruction: "Hold 3 seconds, then slowly lower."),
        ],
        caregiverTip: "Start with both feet together. Progress to single-leg."
    )

    // — Twisted / Rolled Ankle —

    static let towelScrunches = Exercise(
        name: "Towel Scrunches", bodyArea: .ankle,
        visualDescription: "Place a towel on the floor. Use your toes to scrunch it toward you.",
        targetAngleRange: 80...100, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit with a towel flat on the floor under your foot."),
            ExerciseStep(stepNumber: 2, title: "Scrunch", instruction: "Use your toes to scrunch the towel toward you."),
            ExerciseStep(stepNumber: 3, title: "Release", instruction: "Spread the towel back out and repeat."),
        ],
        caregiverTip: "Rebuilds intrinsic foot and lower ankle stability."
    )

    static let singleLegBalance = Exercise(
        name: "Single Leg Balance", bodyArea: .ankle,
        visualDescription: "Stand on the affected foot near a wall for support. Hold 30 seconds.",
        targetAngleRange: 170...180, holdSeconds: 30, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Stand near a wall or chair for support."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Lift the unaffected foot off the ground."),
            ExerciseStep(stepNumber: 3, title: "Balance", instruction: "Hold 30 seconds. Touch the wall if needed."),
        ],
        caregiverTip: "Stay close — they may wobble. Remove wall touch as balance improves."
    )

    static let resistanceDorsiflexion = Exercise(
        name: "Resistance Dorsiflexion", bodyArea: .ankle,
        visualDescription: "Loop a resistance band around the top of your foot. Pull toes toward you against the band.",
        targetAngleRange: 70...90, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit with leg straight. Loop a band around the top of the foot."),
            ExerciseStep(stepNumber: 2, title: "Pull", instruction: "Pull toes toward you against the band's resistance."),
            ExerciseStep(stepNumber: 3, title: "Release", instruction: "Slowly return. Repeat 10 times."),
        ],
        caregiverTip: "Anchor the band securely. Start with light resistance."
    )

    // — Broken Ankle / Pain Rotating —

    static let anklePumps = Exercise(
        name: "Ankle Pumps", bodyArea: .ankle,
        visualDescription: "Lie down. Point toes away from you, then pull them back toward you. Repeat rhythmically.",
        targetAngleRange: 70...110, holdSeconds: 2, reps: 20,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie down", instruction: "Lie on your back with legs straight."),
            ExerciseStep(stepNumber: 2, title: "Point", instruction: "Point toes away from you (plantar flexion)."),
            ExerciseStep(stepNumber: 3, title: "Pull back", instruction: "Pull toes toward you (dorsiflexion). Repeat."),
        ],
        caregiverTip: "Ideal first exercise after fracture or surgery. Promotes circulation."
    )

    static let seatedToeRaises = Exercise(
        name: "Seated Toe Raises", bodyArea: .ankle,
        visualDescription: "Sit with feet flat. Lift just the toes off the floor, keeping heels down.",
        targetAngleRange: 70...90, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", instruction: "Sit with feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Lift toes off the floor, keeping heels planted."),
            ExerciseStep(stepNumber: 3, title: "Lower", instruction: "Hold 3 seconds, then lower."),
        ],
        caregiverTip: "Restores dorsiflexion range critical for walking normally."
    )

    static let seatedHeelRaises = Exercise(
        name: "Seated Heel Raises", bodyArea: .ankle,
        visualDescription: "Sit with feet flat. Lift heels off the floor, keeping toes down.",
        targetAngleRange: 100...130, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", instruction: "Sit with feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Raise heels off the floor, pressing through the toes."),
            ExerciseStep(stepNumber: 3, title: "Lower", instruction: "Hold 3 seconds, then lower slowly."),
        ],
        caregiverTip: "Safe starting point for restoring plantar flexion after injury."
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: ── SHOULDER (9 exercises) ──────────────────────────────
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Exercise {

    // — General Pain —

    static let pendulumSwings = Exercise(
        name: "Pendulum Swings", bodyArea: .shoulder,
        visualDescription: "Lean forward with support. Let your arm hang and swing in small circles.",
        targetAngleRange: 0...30, holdSeconds: 0, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lean", instruction: "Lean forward, supporting yourself with the good arm."),
            ExerciseStep(stepNumber: 2, title: "Swing", instruction: "Let the affected arm hang loose. Swing in small circles."),
            ExerciseStep(stepNumber: 3, title: "Reverse", instruction: "Reverse direction after 10 swings."),
        ],
        caregiverTip: "Arm should be completely relaxed — no muscle effort."
    )

    static let shoulderRolls = Exercise(
        name: "Shoulder Rolls", bodyArea: .shoulder,
        visualDescription: "Stand or sit upright. Roll both shoulders forward, up, back, and down in circles.",
        targetAngleRange: 0...20, holdSeconds: 0, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Stand or sit upright, arms at your sides."),
            ExerciseStep(stepNumber: 2, title: "Roll forward", instruction: "Roll shoulders forward in smooth circles 10 times."),
            ExerciseStep(stepNumber: 3, title: "Roll backward", instruction: "Reverse direction for 10 more rolls."),
        ],
        caregiverTip: "Slow, full circles. Ideal warm-up for any shoulder condition."
    )

    static let crossBodyStretch = Exercise(
        name: "Cross-Body Stretch", bodyArea: .shoulder,
        visualDescription: "Bring one arm across your chest. Use the other hand to gently pull it closer.",
        targetAngleRange: 0...30, holdSeconds: 15, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Reach", instruction: "Bring the affected arm across your chest."),
            ExerciseStep(stepNumber: 2, title: "Pull", instruction: "Use the other hand to pull it gently closer."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 15 seconds. Feel a stretch in the back of the shoulder."),
        ],
        caregiverTip: "Targets the posterior capsule — common source of stiffness."
    )

    // — Dislocated Shoulder —

    static let sleeperStretch = Exercise(
        name: "Sleeper Stretch", bodyArea: .shoulder,
        visualDescription: "Lie on the affected side, elbow at 90°. Use the other hand to push the forearm toward the floor.",
        targetAngleRange: 30...60, holdSeconds: 5, reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie down", instruction: "Lie on your affected side, elbow bent 90°."),
            ExerciseStep(stepNumber: 2, title: "Press", instruction: "Use the other hand to push forearm toward the floor."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds. Mild stretch only."),
        ],
        caregiverTip: "Very gentle pressure. Stop if sharp pain occurs."
    )

    static let wallSlidesShoulder = Exercise(
        name: "Wall Slides", bodyArea: .shoulder,
        visualDescription: "Stand facing a wall. Slide hands upward as high as comfortable.",
        targetAngleRange: 90...150, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Face wall", instruction: "Stand arm's length from a wall, palms flat."),
            ExerciseStep(stepNumber: 2, title: "Slide up", instruction: "Slide hands upward as far as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Lower", instruction: "Hold 3 seconds at the top, then slowly lower."),
        ],
        caregiverTip: "Mark today's highest point — watching it rise daily is motivating."
    )

    static let externalRotation = Exercise(
        name: "External Rotation", bodyArea: .shoulder,
        visualDescription: "Elbow at 90° against your side. Rotate forearm outward.",
        targetAngleRange: 20...50, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Bend elbow 90°, tucked at your side."),
            ExerciseStep(stepNumber: 2, title: "Rotate", instruction: "Rotate forearm outward, keeping elbow tucked."),
            ExerciseStep(stepNumber: 3, title: "Return", instruction: "Slowly return. Repeat."),
        ],
        caregiverTip: "Keep a rolled towel between elbow and ribs to keep elbow tucked."
    )

    // — Pain Lifting / Moving Arm —

    static let scapularSetting = Exercise(
        name: "Scapular Setting", bodyArea: .shoulder,
        visualDescription: "Stand or sit. Squeeze shoulder blades together and down. Hold.",
        targetAngleRange: 0...10, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Stand or sit upright, arms relaxed."),
            ExerciseStep(stepNumber: 2, title: "Squeeze", instruction: "Squeeze shoulder blades together and down."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds, then relax."),
        ],
        caregiverTip: "Foundation of rotator cuff recovery. No arm movement — just the blades."
    )

    static let supineShoulderFlexion = Exercise(
        name: "Supine Shoulder Flexion", bodyArea: .shoulder,
        visualDescription: "Lie on your back. Use both hands to lift a stick (or the good arm lifts the affected arm) overhead.",
        targetAngleRange: 120...170, holdSeconds: 5, reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie down", instruction: "Lie on your back, arms at sides."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Use a stick or the good arm to lift both arms overhead."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds at end range, then lower."),
        ],
        caregiverTip: "Gravity assists at full elevation. Encourage relaxation at end range."
    )

    static let sideLyingExternalRotation = Exercise(
        name: "Side-Lying External Rotation", bodyArea: .shoulder,
        visualDescription: "Lie on the unaffected side. Elbow bent 90° resting on your hip. Rotate forearm upward.",
        targetAngleRange: 20...50, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie down", instruction: "Lie on the unaffected side, affected elbow on hip at 90°."),
            ExerciseStep(stepNumber: 2, title: "Rotate up", instruction: "Rotate forearm upward toward the ceiling."),
            ExerciseStep(stepNumber: 3, title: "Lower", instruction: "Hold 3 seconds, then slowly lower."),
        ],
        caregiverTip: "Most effective for rotator cuff strength after dislocation or impingement."
    )

    static let standingShoulderFlexion = Exercise(
        name: "Standing Shoulder Flexion", bodyArea: .shoulder,
        visualDescription: "Stand with arm at your side. Raise the arm forward and upward as high as comfortable.",
        targetAngleRange: 90...150, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Stand upright with the affected arm at your side, palm facing in."),
            ExerciseStep(stepNumber: 2, title: "Raise", instruction: "Lift your arm forward and upward as high as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds at the top, then slowly lower."),
        ],
        caregiverTip: "Stand at the side to guide if needed. Encourage a slow, controlled arc."
    )
}

// MARK: - Legacy Accessors (backward compat — now AR-trackable only)

extension Exercise {
    static let kneeFlexionExercises: [Exercise] = [.heelSlides, .seatedKneeFlexion, .proneKneeFlexion]
    static let kneeExtensionExercises: [Exercise] = [.straightLegRaises, .quadSets, .terminalKneeExtension]
    static let shoulderExercises: [Exercise] = [.shoulderRolls, .wallSlidesShoulder, .externalRotation, .supineShoulderFlexion, .sideLyingExternalRotation, .standingShoulderFlexion]
    static let ankleExercises: [Exercise] = [.singleLegBalance, .standingHipFlexion, .seatedKneeExtension]
    static let hipExercises: [Exercise] = [.clamshells, .gluteBridges, .standingHipFlexion]
    static let elbowExercises: [Exercise] = [.elbowFlexionExtension, .activeElbowFlexion, .gravityElbowExtension]
}
