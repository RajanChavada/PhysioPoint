import SwiftUI

struct TriageView: View {
    @EnvironmentObject var appState: PhysioPointState
    @State private var selectedArea: BodyArea? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedArea == nil {
                // Step 1: Body map selection
                bodyMapSection
            } else {
                // Step 2: Show conditions for the selected area
                conditionListSection
            }
        }
        .navigationTitle("Where does it hurt?")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Body Map
    
    private var bodyMapSection: some View {
        VStack(spacing: 16) {
            Text("Tap the area that needs rehab")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 12)
            
            AdaptiveBodyMapView { area in
                withAnimation {
                    selectedArea = area
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Condition List
    
    private var conditionListSection: some View {
        VStack(spacing: 12) {
            // Header with back button
            HStack {
                Button {
                    withAnimation { selectedArea = nil }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Body Map")
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                Text(selectedArea?.rawValue ?? "")
                    .font(.headline)
                
                Spacer()
                // Balance the layout
                Color.clear.frame(width: 80, height: 1)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            let conditions = Condition.conditions(for: selectedArea ?? .knee)
            
            if conditions.isEmpty {
                Spacer()
                Text("Coming soon for this area.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(conditions) { condition in
                    Button {
                        appState.selectedCondition = condition
                        appState.navigationPath.append("Schedule")
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(condition.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(condition.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
