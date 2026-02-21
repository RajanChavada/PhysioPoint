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
    
    /// Called when body tracking is lost
    public func bodyLost() {
        DispatchQueue.main.async {
            self.isBodyDetected = false
            self.feedbackMessage = "Step back so full body is in frame"
        }
    }
}

public struct ExerciseARView: View {
    @StateObject private var viewModel = RehabSessionViewModel()
    @EnvironmentObject var appState: PhysioPointState
    
    public init() {}
    
    public var body: some View {
        ZStack {
            #if os(iOS) && !targetEnvironment(simulator)
            if ARBodyTrackingConfiguration.isSupported {
                ARViewRepresentable(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
            } else {
                fallbackSimulatorView()
            }
            #else
            fallbackSimulatorView()
            #endif
            
            VStack {
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
                .padding(.top, 10)
                
                Text(viewModel.feedbackMessage)
                    .font(.headline)
                    .padding()
                    .background(feedbackColor.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 4)
                
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
                    VStack {
                        Text("Reps: \(viewModel.repsCompleted)")
                            .font(.largeTitle)
                            .bold()
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
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
    
    /// Color for the feedback banner based on zone
    private var feedbackColor: Color {
        switch viewModel.angleZone {
        case .belowTarget: return .orange
        case .target: return .green
        case .aboveTarget: return .blue
        }
    }
    
    /// Color for the large angle number
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
                Text("AR Not Supported. Demo Slider:")
                    .foregroundColor(.white)
                    .padding()
                
                Slider(value: Binding(
                    get: { viewModel.currentAngle },
                    set: { newAngle in
                        let radians = Float(newAngle) * .pi / 180.0
                        // Fix hip to 0.5 up, knee at 0,0, ankle swinging based on angle
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

#if os(iOS) && !targetEnvironment(simulator)
struct ARViewRepresentable: UIViewRepresentable {
    let viewModel: RehabSessionViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Disable unnecessary rendering for performance
        arView.renderOptions = [.disablePersonOcclusion, .disableMotionBlur]
        
        let config = ARBodyTrackingConfiguration()
        config.automaticSkeletonScaleEstimationEnabled = true
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = context.coordinator
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: RehabSessionViewModel
        weak var arView: ARView?
        
        // We anchor all visuals relative to the body anchor itself
        var bodyAnchorEntity: AnchorEntity?
        
        // Joint spheres — larger for visibility
        var hipSphere: ModelEntity?
        var kneeSphere: ModelEntity?
        var ankleSphere: ModelEntity?
        
        // Skeleton line segments
        var upperLegLine: ModelEntity?
        var lowerLegLine: ModelEntity?
        
        // Track if we've seen the body at least once
        var hasDetectedBody = false
        
        init(viewModel: RehabSessionViewModel) {
            self.viewModel = viewModel
        }
        
        // MARK: - Visual Setup
        
        private func createJointSphere(color: UIColor, radius: Float = 0.05) -> ModelEntity {
            let mesh = MeshResource.generateSphere(radius: radius)
            var material = UnlitMaterial(color: color)
            // Semi-transparent so user can see their body behind the dots
            material.color.tint = color.withAlphaComponent(0.85)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            return entity
        }
        
        private func createLineBetween(from: SIMD3<Float>, to: SIMD3<Float>, color: UIColor) -> ModelEntity {
            let distance = simd_distance(from, to)
            guard distance > 0.001 else {
                return ModelEntity()
            }
            
            // Thin cylinder as a "bone" line
            let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.015, distance, 0.015), cornerRadius: 0.005)
            let material = UnlitMaterial(color: color.withAlphaComponent(0.7))
            let entity = ModelEntity(mesh: mesh, materials: [material])
            
            // Position at midpoint
            let midpoint = (from + to) / 2.0
            entity.position = midpoint
            
            // Orient the cylinder to point from `from` to `to`
            let direction = normalize(to - from)
            let up = SIMD3<Float>(0, 1, 0)
            entity.orientation = simd_quatf(from: up, to: direction)
            
            return entity
        }
        
        private func setupVisualsIfNeeded() {
            guard bodyAnchorEntity == nil, let arView = arView else { return }
            
            // Create an anchor that lives at the world origin.
            // We'll position joints in world space.
            let anchor = AnchorEntity(world: .zero)
            arView.scene.addAnchor(anchor)
            
            // Joint dots
            let hip = createJointSphere(color: .systemGreen, radius: 0.06)
            let knee = createJointSphere(color: .systemYellow, radius: 0.06)
            let ankle = createJointSphere(color: .systemRed, radius: 0.06)
            
            anchor.addChild(hip)
            anchor.addChild(knee)
            anchor.addChild(ankle)
            
            self.hipSphere = hip
            self.kneeSphere = knee
            self.ankleSphere = ankle
            
            // Skeleton lines (will be replaced each frame)
            let upperLine = ModelEntity()
            let lowerLine = ModelEntity()
            anchor.addChild(upperLine)
            anchor.addChild(lowerLine)
            self.upperLegLine = upperLine
            self.lowerLegLine = lowerLine
            
            self.bodyAnchorEntity = anchor
        }
        
        private func updateLine(entity: ModelEntity?, from: SIMD3<Float>, to: SIMD3<Float>, color: UIColor) {
            guard let entity = entity else { return }
            
            let distance = simd_distance(from, to)
            guard distance > 0.001 else { return }
            
            // Update mesh
            entity.model?.mesh = MeshResource.generateBox(
                size: SIMD3<Float>(0.02, distance, 0.02),
                cornerRadius: 0.005
            )
            entity.model?.materials = [UnlitMaterial(color: color.withAlphaComponent(0.6))]
            
            // Position at midpoint
            entity.position = (from + to) / 2.0
            
            // Orient along the bone direction
            let direction = normalize(to - from)
            let up = SIMD3<Float>(0, 1, 0)
            entity.orientation = simd_quatf(from: up, to: direction)
        }
        
        // MARK: - Joint Extraction
        
        private func worldPosition(of jointName: String, in bodyAnchor: ARBodyAnchor) -> SIMD3<Float>? {
            let skeleton = bodyAnchor.skeleton
            guard let jointTransform = skeleton.modelTransform(
                for: ARSkeleton.JointName(rawValue: jointName)
            ) else {
                return nil
            }
            // Model transform is relative to the body anchor's root.
            // Multiply by body anchor's world transform to get world position.
            let worldTransform = bodyAnchor.transform * jointTransform
            return SIMD3<Float>(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z
            )
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Body anchor is delivered here first, then updated via didUpdate
            processBodyAnchors(anchors)
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            processBodyAnchors(anchors)
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            // If body anchor is removed, user left the frame
            if anchors.contains(where: { $0 is ARBodyAnchor }) {
                viewModel.bodyLost()
            }
        }
        
        private func processBodyAnchors(_ anchors: [ARAnchor]) {
            guard let bodyAnchor = anchors.compactMap({ $0 as? ARBodyAnchor }).first else {
                return
            }
            
            setupVisualsIfNeeded()
            
            // Extract right leg joints (adjust to left if needed)
            guard let hipPos = worldPosition(of: "right_upLeg_joint", in: bodyAnchor)
                    ?? worldPosition(of: "right_up_leg_joint", in: bodyAnchor),
                  let kneePos = worldPosition(of: "right_leg_joint", in: bodyAnchor),
                  let anklePos = worldPosition(of: "right_foot_joint", in: bodyAnchor)
            else {
                // Try alternate joint names for compatibility
                return
            }
            
            // Update sphere positions in world space
            hipSphere?.position = hipPos
            kneeSphere?.position = kneePos
            ankleSphere?.position = anklePos
            
            // Update skeleton lines
            let zoneColor = zoneUIColor()
            updateLine(entity: upperLegLine, from: hipPos, to: kneePos, color: zoneColor)
            updateLine(entity: lowerLegLine, from: kneePos, to: anklePos, color: zoneColor)
            
            // Color-code knee sphere by zone
            let kneeColor: UIColor
            switch viewModel.angleZone {
            case .belowTarget: kneeColor = .systemOrange
            case .target: kneeColor = .systemGreen
            case .aboveTarget: kneeColor = .white
            }
            kneeSphere?.model?.materials = [UnlitMaterial(color: kneeColor.withAlphaComponent(0.9))]
            
            // Feed to rehab engine for angle & rep detection
            viewModel.processJoints(hip: hipPos, knee: kneePos, ankle: anklePos)
        }
        
        private func zoneUIColor() -> UIColor {
            switch viewModel.angleZone {
            case .belowTarget: return .systemOrange
            case .target: return .systemGreen
            case .aboveTarget: return .systemCyan
            }
        }
    }
}
#endif
