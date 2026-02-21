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
    
    private let engine: RehabEngine
    
    public init(engine: RehabEngine = SimpleRehabEngine()) {
        self.engine = engine
    }
    
    public func processJoints(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) {
        let state = engine.update(hip: hip, knee: knee, ankle: ankle)
        let repState = engine.currentRepState
        
        DispatchQueue.main.async {
            self.currentAngle = state.degrees
            self.angleZone = state.zone
            self.repsCompleted = repState.repsCompleted
            if self.currentAngle > self.bestAngle {
                self.bestAngle = self.currentAngle
            }
            
            if repState.isHolding {
                self.feedbackMessage = "Hold it!"
            } else {
                switch state.zone {
                case .belowTarget:
                    self.feedbackMessage = "Bend less"
                case .target:
                    self.feedbackMessage = "Target reached, hold!"
                case .aboveTarget:
                    self.feedbackMessage = "Bend more"
                }
            }
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
                Text(viewModel.feedbackMessage)
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 40)
                
                Text(String(format: "Angle: %.1f°", viewModel.currentAngle))
                    .font(.title2)
                    .foregroundColor(.white)
                
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
                        // Finish Session
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
        let config = ARBodyTrackingConfiguration()
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: RehabSessionViewModel
        
        init(viewModel: RehabSessionViewModel) {
            self.viewModel = viewModel
        }
        
        func getJointPosition(anchor: ARBodyAnchor, jointName: String) -> SIMD3<Float>? {
            guard let transform = anchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) else { return nil }
            let worldTransform = anchor.transform * transform
            return SIMD3<Float>(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let bodyAnchor = anchors.compactMap({ $0 as? ARBodyAnchor }).first else { return }
            
            guard let hip = getJointPosition(anchor: bodyAnchor, jointName: "right_up_leg_joint"),
                  let knee = getJointPosition(anchor: bodyAnchor, jointName: "right_leg_joint"),
                  let ankle = getJointPosition(anchor: bodyAnchor, jointName: "right_foot_joint") else {
                return
            }
            
            viewModel.processJoints(hip: hip, knee: knee, ankle: ankle)
        }
    }
}
#endif
