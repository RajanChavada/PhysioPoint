import SwiftUI

struct TriageView: View {
    @EnvironmentObject var appState: PhysioPointState
    @State private var selectedArea: BodyArea? = nil
    @State private var showConditions = false

    var body: some View {
        ZStack {
            // Background
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
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Where does it hurt?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Tap on the body area where you're\nexperiencing pain.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)

            // Body map in a glass card
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(PPColor.actionBlue.opacity(0.1), lineWidth: 1)
                    )

                AdaptiveBodyMapView { area in
                    selectedArea = area
                }
                .padding(16)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 24)

            // Selection label
            if let area = selectedArea {
                HStack(spacing: 4) {
                    Text("Selected:")
                        .foregroundColor(.secondary)
                    Text(area.rawValue)
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("Tap a zone above to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Continue button
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
                .background(
                    Group {
                        if selectedArea != nil {
                            PPGradient.action
                        } else {
                            LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                        }
                    }
                )
                .cornerRadius(18)
                .shadow(color: selectedArea != nil ? PPColor.vitalityTeal.opacity(0.25) : Color.clear, radius: 10, y: 4)
            }
            .disabled(selectedArea == nil)
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Condition List Section

    private var conditionListSection: some View {
        VStack(spacing: 0) {
            // Header with back
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

            let conditions = Condition.conditions(for: selectedArea ?? .knee)

            if conditions.isEmpty {
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
                        ForEach(conditions) { condition in
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
