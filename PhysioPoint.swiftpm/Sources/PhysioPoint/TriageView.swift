import SwiftUI

// MARK: - BodyZone model

struct BodyZone: Identifiable {
    let id: BodyArea
    let label: String
    let relX: CGFloat   // 0.0 = left edge, 1.0 = right edge of the image
    let relY: CGFloat   // 0.0 = top,        1.0 = bottom of the image
}

// Relative positions tuned for body_front.png (front-facing silhouette)
let bodyZones: [BodyZone] = [
    BodyZone(id: .shoulder, label: "Shoulders", relX: 0.50, relY: 0.22),
    BodyZone(id: .elbow,    label: "Elbows",    relX: 0.50, relY: 0.38),
    BodyZone(id: .hip,      label: "Hips",      relX: 0.50, relY: 0.52),
    BodyZone(id: .knee,     label: "Knees",     relX: 0.50, relY: 0.68),
    BodyZone(id: .ankle,    label: "Ankles",    relX: 0.50, relY: 0.84),
]

// MARK: - Single glow/tap zone (self-contained to avoid let-in-ViewBuilder)

struct BodyZoneOverlay: View {
    let zone: BodyZone
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let isSelected: Bool
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    // Pixel coordinates derived from relative values
    private var px: CGFloat { zone.relX * frameWidth }
    private var py: CGFloat { zone.relY * frameHeight }

    var body: some View {
        ZStack {
            // Pulsing radial glow — only when selected
            if isSelected {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                PPColor.vitalityTeal.opacity(0.55),
                                PPColor.vitalityTeal.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 36
                        )
                    )
                    .frame(width: 72, height: 72)
                    .blur(radius: 4)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.18
                        }
                    }

                // Crisp inner ring
                Circle()
                    .stroke(PPColor.vitalityTeal, lineWidth: 2)
                    .frame(width: 44, height: 44)
            } else {
                // Subtle idle ring so zones are discoverable
                Circle()
                    .stroke(PPColor.actionBlue.opacity(0.22), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
            }

            // Invisible tap target
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: 64, height: 64)
                .contentShape(Circle())
                .onTapGesture { onTap() }

            // Label pill — floats to the right
            Text(zone.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : PPColor.actionBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? PPColor.vitalityTeal.opacity(0.85)
                              : Color.white.opacity(0.80))
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                )
                .offset(x: 58, y: 0)
        }
        .position(x: px, y: py)
    }
}

// MARK: - TriageView

struct TriageView: View {
    @EnvironmentObject var appState: PhysioPointState
    @State private var selectedArea: BodyArea? = nil
    @State private var showConditions = false

    var body: some View {
        ZStack {
            PPGradient.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if !showConditions {
                    bodyMapSection
                } else {
                    conditionListSection
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Body Map Section

    private var bodyMapSection: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 6) {
                Text("Where does it hurt?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Tap the body area that needs care")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            // Body image + glow overlays via GeometryReader
            GeometryReader { geo in
                ZStack {
                    // Body silhouette fills the frame
                    BundledImage("body_front", maxHeight: geo.size.height)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .opacity(0.85)

                    // One overlay per zone — each is a self-contained view
                    ForEach(bodyZones) { zone in
                        BodyZoneOverlay(
                            zone: zone,
                            frameWidth: geo.size.width,
                            frameHeight: geo.size.height,
                            isSelected: selectedArea == zone.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                selectedArea = zone.id
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .padding(.horizontal, 60)

            Spacer(minLength: 0)

            // Selection label + Continue button
            VStack(spacing: 12) {
                selectionLabel

                Button {
                    withAnimation(.spring(response: 0.35)) {
                        showConditions = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(continueBackground)
                    .cornerRadius(18)
                    .shadow(color: selectedArea != nil
                            ? PPColor.vitalityTeal.opacity(0.25)
                            : Color.clear,
                            radius: 10, y: 4)
                }
                .disabled(selectedArea == nil)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
    }

    private var selectionLabel: some View {
        Group {
            if let area = selectedArea {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(PPColor.vitalityTeal)
                    Text("Selected:").foregroundColor(.secondary)
                    Text(area.rawValue).fontWeight(.bold)
                }
                .font(.subheadline)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("Tap a zone above to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var continueBackground: some View {
        Group {
            if selectedArea != nil {
                PPGradient.action
            } else {
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                    startPoint: .leading, endPoint: .trailing
                )
            }
        }
    }

    // MARK: - Condition List Section

    private var conditionListSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        showConditions = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Body Map")
                    }
                    .font(.subheadline)
                    .foregroundColor(PPColor.actionBlue)
                }
                Spacer()
                Text(selectedArea?.rawValue ?? "")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 80, height: 1)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            conditionsList
        }
    }

    private var filteredConditions: [Condition] {
        Condition.conditions(for: selectedArea ?? .knee)
    }

    private var conditionsList: some View {
        Group {
            if filteredConditions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Coming soon for this area.")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredConditions) { condition in
                            Button {
                                appState.selectedCondition = condition
                                appState.navigationPath.append("Schedule")
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(condition.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(condition.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(PPColor.actionBlue)
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(PPColor.actionBlue.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
