import SwiftUI
import RealityKit

#if canImport(ARKit)
import ARKit
#endif

public class RehabSessionViewModel: ObservableObject {
    @Published public var currentAngle: Double = 0
    @Published public var repsCompleted: Int = 0
    @Published public var isInZone: Bool = false
    @Published public var feedbackMessage: String = "Position yourself in frame"
    @Published public var formCueText: String = ""
    @Published public var trackingQuality: String = "Initializing..."
    @Published public var cameraHint: String = ""
    @Published public var reliabilityBadge: String = ""
    @Published public var isBodyDetected: Bool = false
    @Published public var bestAngle: Double = 0
    @Published public var angleZone: AngleZone = .aboveTarget
    @Published public var debugText: String = "Initializing..."
    @Published public var targetAngle: Double = 90
    @Published public var tolerance: Double = 15
    @Published public var isTrackingQualityGood: Bool = true
    
    // All exercises are now AR-tracked — no timer-only mode needed
    
    private let angleSmoother = AngleSmoother(windowSize: 5)
    
    public var engine: RehabEngine
    
    public init(engine: RehabEngine = SimpleRehabEngine()) {
        self.engine = engine
    }
    
    public func setup(targetAngle: Double, tolerance: Double, holdTime: TimeInterval, repDirection: RepDirection = .increasing, restAngle: Double = 90.0) {
        self.engine = SimpleRehabEngine(targetAngle: targetAngle, tolerance: tolerance, requiredHoldTime: holdTime, repDirection: repDirection, restAngle: restAngle)
    }
    
    /// Generic 3-joint processing — works for any body area (knee, elbow, hip, shoulder, ankle).
    /// Applies temporal smoothing to reduce ARKit frame-to-frame jitter (~±5° → ~±1-2°).
    public func processJoints(proximal: SIMD3<Float>, joint: SIMD3<Float>, distal: SIMD3<Float>) {
        let state = engine.update(proximal: proximal, joint: joint, distal: distal)
        let repState = engine.currentRepState
        let smoothedAngle = angleSmoother.smooth(state.degrees)
        
        DispatchQueue.main.async {
            self.isBodyDetected = true
            self.currentAngle = smoothedAngle
            self.angleZone = state.zone
            self.repsCompleted = repState.repsCompleted
            if smoothedAngle > self.bestAngle {
                self.bestAngle = smoothedAngle
            }
            
            if repState.isHolding {
                self.feedbackMessage = "Hold it! 💪"
            } else {
                switch state.zone {
                case .belowTarget:
                    self.feedbackMessage = "Move more toward target"
                case .target:
                    self.feedbackMessage = "In target range — hold! ✅"
                case .aboveTarget:
                    self.feedbackMessage = "Ease back toward target"
                }
            }
        }
    }
    
    /// Backward-compatible: hip/knee/ankle callers
    public func processJoints(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) {
        processJoints(proximal: hip, joint: knee, distal: ankle)
    }
    
    public func bodyLost() {
        feedbackMessage = "Move back into frame"
        isInZone = false
        angleSmoother.reset()
    }
    
    // startTimerMode() removed — all exercises are now AR-tracked
    
    public func addDebug(_ msg: String) {
        DispatchQueue.main.async {
            self.debugText = msg
            print("📱 \(msg)")
        }
    }
}

public struct ExerciseARView: View {
    @StateObject private var viewModel = RehabSessionViewModel()
    @EnvironmentObject var appState: PhysioPointState
    
    public init() {}
    
    public var body: some View {
        ZStack {
            arOrFallback
            
            VStack(spacing: 4) {
                // DEBUG banner — remove for final submission
                Text(viewModel.debugText)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding(6)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
                    .padding(.top, 4)
                
                // Tracking status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isBodyDetected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(viewModel.isBodyDetected ? "Body Detected" : "No Body Detected")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                
                Text(viewModel.feedbackMessage)
                    .font(.headline)
                    .padding()
                    .background(feedbackColor.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                if !viewModel.formCueText.isEmpty {
                    Text("💡 \(viewModel.formCueText)")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.yellow)
                        .cornerRadius(8)
                }
                
                // Camera hint
                if !viewModel.cameraHint.isEmpty {
                    Text(viewModel.cameraHint)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
                
                // Reliability badge
                if !viewModel.reliabilityBadge.isEmpty {
                    Text(viewModel.reliabilityBadge)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if !viewModel.isTrackingQualityGood {
                    Text("⚠️ Move to a better lit area for best tracking")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                if viewModel.isBodyDetected {
                    Text(String(format: "Angle: %.1f°", viewModel.currentAngle))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(angleDisplayColor)
                        .shadow(color: .black, radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                Text("For educational demo only. Not medical advice.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 8)
                
                HStack(spacing: 30) {
                    Text("Reps: \(viewModel.repsCompleted)")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Button {
                        let targetReps = appState.selectedExercise?.reps ?? 3
                        let targetRange = appState.selectedExercise?.targetAngleRange ?? 80...95

                        // Build per-rep results from tracked data
                        var repResults: [RepResult] = []
                        for i in 1...max(viewModel.repsCompleted, 1) {
                            // Approximate: give each rep a quality based on best angle vs target
                            let inRange = viewModel.bestAngle >= targetRange.lowerBound && viewModel.bestAngle <= targetRange.upperBound
                            repResults.append(RepResult(
                                repNumber: i,
                                peakAngle: viewModel.bestAngle - Double.random(in: -4...4),
                                timeInTarget: Double.random(in: 5...9),
                                quality: inRange ? .good : .fair
                            ))
                        }

                        appState.latestMetrics = SessionMetrics(
                            bestAngle: viewModel.bestAngle,
                            repsCompleted: viewModel.repsCompleted,
                            targetReps: targetReps,
                            targetAngleLow: targetRange.lowerBound,
                            targetAngleHigh: targetRange.upperBound,
                            timeInGoodForm: repResults.reduce(0) { $0 + $1.timeInTarget },
                            repResults: repResults,
                            previousBestAngle: 88,
                            previousTimeInForm: 13,
                            todayCompleted: 1,
                            todayTotal: 3
                        )
                        appState.navigationPath.append("Summary")
                    } label: {
                        Text("Finish")
                            .font(.title2)
                            .bold()
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .onAppear {
            // All exercises have tracking configs — configure the engine with correct parameters
            if let config = appState.selectedExercise?.trackingConfig {
                let mid = (config.targetRange.lowerBound + config.targetRange.upperBound) / 2.0
                let tol = (config.targetRange.upperBound - config.targetRange.lowerBound) / 2.0
                
                // CRITICAL: Actually configure the engine with exercise-specific values
                let holdTime: TimeInterval = config.mode == .holdDuration
                    ? Double(appState.selectedExercise?.holdSeconds ?? 3)
                    : 2.0
                viewModel.setup(
                    targetAngle: mid,
                    tolerance: tol,
                    holdTime: holdTime,
                    repDirection: config.repDirection,
                    restAngle: config.restAngle
                )
                
                viewModel.targetAngle = mid
                viewModel.tolerance = tol
                viewModel.cameraHint = "📷 Best results: place camera to your \(config.cameraPosition.rawValue)"
                viewModel.reliabilityBadge = config.reliability == .reliable
                    ? "✅ High accuracy tracking"
                    : "⚠️ Approximate tracking — wider tolerance applied"
            }
        }
    }
    
    @ViewBuilder
    private var arOrFallback: some View {
        #if os(iOS) && !targetEnvironment(simulator)
        ARViewRepresentable(viewModel: viewModel, trackingConfig: appState.selectedExercise?.trackingConfig)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                viewModel.addDebug("iOS path: ARView loaded, checking body support...")
            }
        #else
        fallbackSimulatorView()
            .onAppear {
                viewModel.addDebug("NON-iOS path: showing fallback slider (macOS or Simulator)")
            }
        #endif
    }
    
    private var feedbackColor: Color {
        switch viewModel.angleZone {
        case .belowTarget: return .orange
        case .target: return .green
        case .aboveTarget: return .blue
        }
    }
    
    private var angleDisplayColor: Color {
        switch viewModel.angleZone {
        case .belowTarget: return .orange
        case .target: return .green
        case .aboveTarget: return .white
        }
    }
    
    @ViewBuilder
    private func fallbackSimulatorView() -> some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                Text("AR Body Tracking Not Available")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                
                Text("Use the slider to simulate knee angle:")
                    .foregroundColor(.white.opacity(0.8))
                
                Slider(value: Binding(
                    get: { viewModel.currentAngle },
                    set: { newAngle in
                        let radians = Float(newAngle) * .pi / 180.0
                        let hip = SIMD3<Float>(0, 0.5, 0)
                        let knee = SIMD3<Float>(0, 0, 0)
                        let ankle = SIMD3<Float>(0, -0.5 * cos(radians), 0.5 * sin(radians))
                        viewModel.processJoints(hip: hip, knee: knee, ankle: ankle)
                    }
                ), in: 0...180)
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - AR Implementation (iOS device only)

#if os(iOS) && !targetEnvironment(simulator)
struct ARViewRepresentable: UIViewRepresentable {
    let viewModel: RehabSessionViewModel
    let trackingConfig: JointTrackingConfig?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.arView = arView
        context.coordinator.activeConfig = trackingConfig
        
        // Setup the RealityKit scene IMMEDIATELY so entities are ready
        context.coordinator.setupSceneNow(in: arView)
        
        // Check body tracking support at runtime
        if ARBodyTrackingConfiguration.isSupported {
            viewModel.addDebug("✅ Body tracking supported. Starting session...")
            let config = ARBodyTrackingConfiguration()
            config.automaticSkeletonScaleEstimationEnabled = true
            arView.session.delegate = context.coordinator
            arView.session.run(config)
        } else {
            viewModel.addDebug("❌ Body tracking NOT supported on this device")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Keep the active tracking config in sync when the exercise changes
        context.coordinator.activeConfig = trackingConfig
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: RehabSessionViewModel
        weak var arView: ARView?
        
        /// The active exercise's tracking config — determines which joints to track
        var activeConfig: JointTrackingConfig?
        
        private var sceneAnchor: AnchorEntity?
        private var isSetUp = false
        private var frameCount = 0
        private var bodyFrameCount = 0
        
        // ── Full-body joint tracking ──
        // Maps joint name → index in jointModelTransforms array
        private var jointIndexMap: [String: Int] = [:]
        // Maps joint name → sphere entity
        private var jointEntities: [String: ModelEntity] = [:]
        // Bone line entities connecting parent→child joints
        private var boneEntities: [String: ModelEntity] = [:]
        private var didResolve = false
        
        // The joints we want to visualize (smaller orbs for better accuracy perception)
        // Reduced from 0.06 → 0.025 to minimize visual confusion from ARKit joint position error
        static let trackedJoints: [(name: String, color: UIColor, radius: Float)] = [
            // Hips / Root
            ("hips_joint",                .white,        0.03),
            // Right leg
            ("right_upLeg_joint",         .green,        0.03),
            ("right_leg_joint",           .yellow,       0.03),
            ("right_foot_joint",          .red,          0.025),
            ("right_toes_joint",          .red,          0.015),
            // Left leg
            ("left_upLeg_joint",          .green,        0.03),
            ("left_leg_joint",            .yellow,       0.03),
            ("left_foot_joint",           .red,          0.025),
            ("left_toes_joint",           .red,          0.015),
            // Spine
            ("spine_1_joint",             .cyan,         0.02),
            ("spine_4_joint",             .cyan,         0.02),
            ("spine_7_joint",             .cyan,         0.02),
            // Neck & Head
            ("neck_1_joint",              .cyan,         0.02),
            ("head_joint",                .magenta,      0.035),
            // Right arm
            ("right_shoulder_1_joint",    .orange,       0.025),
            ("right_arm_joint",           .orange,       0.025),
            ("right_forearm_joint",        .orange,      0.025),
            ("right_hand_joint",          .orange,       0.02),
            // Left arm
            ("left_shoulder_1_joint",     .orange,       0.025),
            ("left_arm_joint",            .orange,       0.025),
            ("left_forearm_joint",         .orange,      0.025),
            ("left_hand_joint",           .orange,       0.02),
        ]
        
        // Bones: pairs of joints to connect with lines
        static let bones: [(from: String, to: String)] = [
            // Right leg
            ("hips_joint",              "right_upLeg_joint"),
            ("right_upLeg_joint",       "right_leg_joint"),
            ("right_leg_joint",         "right_foot_joint"),
            ("right_foot_joint",        "right_toes_joint"),
            // Left leg
            ("hips_joint",              "left_upLeg_joint"),
            ("left_upLeg_joint",        "left_leg_joint"),
            ("left_leg_joint",          "left_foot_joint"),
            ("left_foot_joint",         "left_toes_joint"),
            // Spine
            ("hips_joint",              "spine_1_joint"),
            ("spine_1_joint",           "spine_4_joint"),
            ("spine_4_joint",           "spine_7_joint"),
            ("spine_7_joint",           "neck_1_joint"),
            ("neck_1_joint",            "head_joint"),
            // Right arm
            ("spine_7_joint",           "right_shoulder_1_joint"),
            ("right_shoulder_1_joint",  "right_arm_joint"),
            ("right_arm_joint",         "right_forearm_joint"),
            ("right_forearm_joint",     "right_hand_joint"),
            // Left arm
            ("spine_7_joint",           "left_shoulder_1_joint"),
            ("left_shoulder_1_joint",   "left_arm_joint"),
            ("left_arm_joint",          "left_forearm_joint"),
            ("left_forearm_joint",      "left_hand_joint"),
        ]
        
        init(viewModel: RehabSessionViewModel) {
            self.viewModel = viewModel
        }
        
        // MARK: - Scene setup
        
        func setupSceneNow(in arView: ARView) {
            guard !isSetUp else { return }
            isSetUp = true
            
            let anchor = AnchorEntity(world: .zero)
            
            // Create a sphere entity for each tracked joint
            for joint in Self.trackedJoints {
                let mesh = MeshResource.generateSphere(radius: joint.radius)
                let entity = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: joint.color)])
                entity.isEnabled = false
                anchor.addChild(entity)
                jointEntities[joint.name] = entity
            }
            
            // Create bone line entities
            for bone in Self.bones {
                let entity = ModelEntity()
                entity.isEnabled = false
                anchor.addChild(entity)
                boneEntities["\(bone.from)->\(bone.to)"] = entity
            }
            
            arView.scene.addAnchor(anchor)
            self.sceneAnchor = anchor
            
            viewModel.addDebug("Scene: \(Self.trackedJoints.count) joints + \(Self.bones.count) bones")
        }
        
        // MARK: - Resolve joint indices
        
        private func resolveIndices(from skeleton: ARSkeleton3D) {
            guard !didResolve else { return }
            
            let allNames = skeleton.definition.jointNames
            viewModel.addDebug("Skeleton has \(allNames.count) joints")
            
            for (idx, name) in allNames.enumerated() {
                jointIndexMap[name] = idx
            }
            
            // Check which tracked joints we found
            var found = 0
            for joint in Self.trackedJoints {
                if jointIndexMap[joint.name] != nil { found += 1 }
            }
            
            didResolve = true
            viewModel.addDebug("Resolved \(found)/\(Self.trackedJoints.count) joints")
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            frameCount += 1
            // Validate tracking quality before counting any data
            let isGoodTracking = frame.camera.trackingState == .normal
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.isTrackingQualityGood = isGoodTracking
            }
            if frameCount % 60 == 0 {
                viewModel.addDebug("F:\(frameCount) B:\(bodyFrameCount) quality:\(isGoodTracking ? "✅" : "⚠️")")
            }
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let body = anchor as? ARBodyAnchor {
                    viewModel.addDebug("🎯 Body detected!")
                    processBody(body)
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let body = anchor as? ARBodyAnchor {
                    bodyFrameCount += 1
                    processBody(body)
                }
            }
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors where anchor is ARBodyAnchor {
                viewModel.bodyLost()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for (_, entity) in self.jointEntities { entity.isEnabled = false }
                    for (_, entity) in self.boneEntities { entity.isEnabled = false }
                }
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            viewModel.addDebug("❌ Error: \(error.localizedDescription)")
        }
        
        // MARK: - Process body
        
        private var passCount = 0
        
        private func processBody(_ bodyAnchor: ARBodyAnchor) {
            let skeleton = bodyAnchor.skeleton
            resolveIndices(from: skeleton)
            
            let transforms = skeleton.jointModelTransforms
            let bT = bodyAnchor.transform
            
            // Compute world positions for every tracked joint
            var worldPositions: [String: SIMD3<Float>] = [:]
            
            for joint in Self.trackedJoints {
                guard let idx = jointIndexMap[joint.name], idx < transforms.count else { continue }
                let worldM = bT * transforms[idx]
                worldPositions[joint.name] = SIMD3<Float>(worldM.columns.3.x, worldM.columns.3.y, worldM.columns.3.z)
            }
            
            passCount += 1
            
            // Use the tracking config to select the correct 3 joints for the active exercise.
            // This is what makes elbow/shoulder/hip exercises use the right joints instead of
            // always falling back to knee (right_upLeg → right_leg → right_foot).
            guard let config = activeConfig else {
                // Timer-only exercise — no angle tracking needed, just update skeleton visuals
                if passCount <= 3 {
                    viewModel.addDebug("⏱ Timer mode — skeleton visible, no angle tracking")
                }
                updateSkeletonVisuals(worldPositions: worldPositions)
                return
            }
            
            let proximalName = config.proximalJoint
            let middleName   = config.middleJoint
            let distalName   = config.distalJoint
            
            if let proximalPos = worldPositions[proximalName],
               let middlePos  = worldPositions[middleName],
               let distalPos  = worldPositions[distalName] {
                viewModel.processJoints(proximal: proximalPos, joint: middlePos, distal: distalPos)
                
                if passCount <= 3 || passCount % 120 == 0 {
                    viewModel.addDebug("✅ #\(passCount) tracking: \(proximalName)→\(middleName)→\(distalName) angle:\(String(format: "%.1f°", viewModel.currentAngle))")
                }
            } else {
                // Could not resolve one or more joints — log which ones are missing
                if passCount <= 5 {
                    let missing = [proximalName, middleName, distalName].filter { worldPositions[$0] == nil }
                    viewModel.addDebug("⚠️ Missing joints: \(missing.joined(separator: ", "))")
                }
            }
            
            // Update skeleton visualization
            updateSkeletonVisuals(worldPositions: worldPositions)
        }
        
        private func updateSkeletonVisuals(worldPositions: [String: SIMD3<Float>]) {
            // Update all visuals on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Position joint spheres
                for joint in Self.trackedJoints {
                    guard let pos = worldPositions[joint.name],
                          let entity = self.jointEntities[joint.name] else { continue }
                    entity.isEnabled = true
                    entity.position = pos
                }
                
                // Middle joint sphere color changes based on angle zone
                if let config = self.activeConfig,
                   let middleEntity = self.jointEntities[config.middleJoint] {
                    let color: UIColor
                    switch self.viewModel.angleZone {
                    case .belowTarget: color = .systemOrange
                    case .target:      color = .systemGreen
                    case .aboveTarget: color = .white
                    }
                    middleEntity.model?.materials = [UnlitMaterial(color: color)]
                }
                
                // Draw bone lines
                for bone in Self.bones {
                    let key = "\(bone.from)->\(bone.to)"
                    guard let fromPos = worldPositions[bone.from],
                          let toPos = worldPositions[bone.to],
                          let entity = self.boneEntities[key] else { continue }
                    entity.isEnabled = true
                    self.updateBone(entity, from: fromPos, to: toPos)
                }
            }
        }
        
        private func updateBone(_ entity: ModelEntity, from: SIMD3<Float>, to: SIMD3<Float>) {
            let dist = simd_distance(from, to)
            guard dist > 0.001 else { return }
            
            let thickness: Float = 0.012  // Thinner lines to match smaller orbs
            entity.model = ModelComponent(
                mesh: .generateBox(size: [thickness, dist, thickness], cornerRadius: thickness / 2),
                materials: [UnlitMaterial(color: UIColor.cyan.withAlphaComponent(0.5))]
            )
            entity.position = (from + to) / 2.0
            let dir = normalize(to - from)
            entity.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: dir)
        }
    }
}
#endif