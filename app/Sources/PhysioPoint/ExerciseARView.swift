import SwiftUI
import RealityKit

#if canImport(ARKit)
import ARKit
#endif

public class RehabSessionViewModel: ObservableObject {
    @Published public var repsCompleted: Int = 0
    @Published public var currentAngle: Double = 0.0
    @Published public var bestAngle: Double = 0.0
    @Published public var angleZone: AngleZone = .aboveTarget
    @Published public var feedbackMessage: String = "Position yourself in camera"
    @Published public var isBodyDetected: Bool = false
    @Published public var debugText: String = "Initializing..."
    
    private var engine: RehabEngine
    
    public init(engine: RehabEngine = SimpleRehabEngine()) {
        self.engine = engine
    }
    
    public func setup(targetAngle: Double, tolerance: Double, holdTime: TimeInterval) {
        self.engine = SimpleRehabEngine(targetAngle: targetAngle, tolerance: tolerance, requiredHoldTime: holdTime)
    }
    
    public func processJoints(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) {
        let state = engine.update(hip: hip, knee: knee, ankle: ankle)
        let repState = engine.currentRepState
        
        DispatchQueue.main.async {
            self.isBodyDetected = true
            self.currentAngle = state.degrees
            self.angleZone = state.zone
            self.repsCompleted = repState.repsCompleted
            if self.currentAngle > self.bestAngle {
                self.bestAngle = self.currentAngle
            }
            
            if repState.isHolding {
                self.feedbackMessage = "Hold it! 💪"
            } else {
                switch state.zone {
                case .belowTarget:
                    self.feedbackMessage = "Bend a little less"
                case .target:
                    self.feedbackMessage = "In target range — hold! ✅"
                case .aboveTarget:
                    self.feedbackMessage = "Bend more toward target"
                }
            }
        }
    }
    
    public func bodyLost() {
        DispatchQueue.main.async {
            self.isBodyDetected = false
            self.feedbackMessage = "Step back so full body is in frame"
        }
    }
    
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
                        appState.latestMetrics = SessionMetrics(
                            bestAngle: viewModel.bestAngle,
                            repsCompleted: viewModel.repsCompleted,
                            targetReps: appState.selectedExercise?.reps ?? 0
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
        .onAppear {
            if let exercise = appState.selectedExercise {
                let lower = exercise.targetAngleRange.lowerBound
                let upper = exercise.targetAngleRange.upperBound
                let targetAngle = (lower + upper) / 2.0
                let tolerance = max((upper - lower) / 2.0, 5.0)
                viewModel.setup(targetAngle: targetAngle, tolerance: tolerance, holdTime: TimeInterval(exercise.holdSeconds))
            }
        }
    }
    
    @ViewBuilder
    private var arOrFallback: some View {
        #if os(iOS) && !targetEnvironment(simulator)
        ARViewRepresentable(viewModel: viewModel)
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
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.arView = arView
        
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
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: RehabSessionViewModel
        weak var arView: ARView?
        
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
        
        // The joints we want to visualize
        static let trackedJoints: [(name: String, color: UIColor, radius: Float)] = [
            // Hips / Root
            ("hips_joint",                .white,        0.06),
            // Right leg
            ("right_upLeg_joint",         .green,        0.06),
            ("right_leg_joint",           .yellow,       0.06),
            ("right_foot_joint",          .red,          0.05),
            ("right_toes_joint",          .red,          0.03),
            // Left leg
            ("left_upLeg_joint",          .green,        0.06),
            ("left_leg_joint",            .yellow,       0.06),
            ("left_foot_joint",           .red,          0.05),
            ("left_toes_joint",           .red,          0.03),
            // Spine
            ("spine_1_joint",             .cyan,         0.04),
            ("spine_4_joint",             .cyan,         0.04),
            ("spine_7_joint",             .cyan,         0.04),
            // Neck & Head
            ("neck_1_joint",              .cyan,         0.04),
            ("head_joint",                .magenta,      0.07),
            // Right arm
            ("right_shoulder_1_joint",    .orange,       0.05),
            ("right_arm_joint",           .orange,       0.05),
            ("right_forearm_joint",        .orange,      0.05),
            ("right_hand_joint",          .orange,       0.04),
            // Left arm
            ("left_shoulder_1_joint",     .orange,       0.05),
            ("left_arm_joint",            .orange,       0.05),
            ("left_forearm_joint",         .orange,      0.05),
            ("left_hand_joint",           .orange,       0.04),
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
            if frameCount % 60 == 0 {
                viewModel.addDebug("F:\(frameCount) B:\(bodyFrameCount) tracking")
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
            
            // Extract right leg positions for the rehab engine
            if let hipPos = worldPositions["right_upLeg_joint"],
               let kneePos = worldPositions["right_leg_joint"],
               let anklePos = worldPositions["right_foot_joint"] {
                viewModel.processJoints(hip: hipPos, knee: kneePos, ankle: anklePos)
                
                if passCount <= 3 || passCount % 120 == 0 {
                    viewModel.addDebug("✅ #\(passCount) joints:\(worldPositions.count) knee:(\(String(format: "%.2f,%.2f,%.2f", kneePos.x, kneePos.y, kneePos.z)))")
                }
            }
            
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
                
                // Right knee sphere color changes based on angle zone
                if let kneeEntity = self.jointEntities["right_leg_joint"] {
                    let color: UIColor
                    switch self.viewModel.angleZone {
                    case .belowTarget: color = .systemOrange
                    case .target:      color = .systemGreen
                    case .aboveTarget: color = .white
                    }
                    kneeEntity.model?.materials = [UnlitMaterial(color: color)]
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
            
            let thickness: Float = 0.02
            entity.model = ModelComponent(
                mesh: .generateBox(size: [thickness, dist, thickness], cornerRadius: thickness / 2),
                materials: [UnlitMaterial(color: UIColor.cyan.withAlphaComponent(0.6))]
            )
            entity.position = (from + to) / 2.0
            let dir = normalize(to - from)
            entity.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: dir)
        }
    }
}
#endif
