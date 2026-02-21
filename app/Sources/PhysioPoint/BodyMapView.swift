import SwiftUI

struct NormalizedBodyRegion: Identifiable {
    let id = UUID()
    let area: BodyArea
    let label: String
    let center: CGPoint  // x, y in 0.0...1.0
    let size: CGSize     // width, height in 0.0...1.0
}

let bodyRegions: [NormalizedBodyRegion] = [
    NormalizedBodyRegion(
        area: .shoulder,
        label: "Shoulders",
        center: CGPoint(x: 0.5, y: 0.22),
        size: CGSize(width: 0.75, height: 0.10)
    ),
    NormalizedBodyRegion(
        area: .hip,
        label: "Hips",
        center: CGPoint(x: 0.5, y: 0.48),
        size: CGSize(width: 0.50, height: 0.10)
    ),
    NormalizedBodyRegion(
        area: .knee,
        label: "Knees",
        center: CGPoint(x: 0.5, y: 0.68),
        size: CGSize(width: 0.40, height: 0.10)
    ),
    NormalizedBodyRegion(
        area: .ankle,
        label: "Ankles",
        center: CGPoint(x: 0.5, y: 0.88),
        size: CGSize(width: 0.40, height: 0.10)
    ),
]

struct AdaptiveBodyMapView: View {
    let onSelect: (BodyArea) -> Void
    @State private var hoveredArea: BodyArea? = nil
    @State private var tappedArea: BodyArea? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Body silhouette image
                BundledImage("body_front", maxHeight: geo.size.height)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(0.6)

                ForEach(bodyRegions) { region in
                    let imageAspect: CGFloat = 0.45 // roughly portrait body shape
                    let viewAspect = geo.size.width / geo.size.height
                    
                    let actualWidth = viewAspect > imageAspect ? geo.size.height * imageAspect : geo.size.width
                    let actualHeight = viewAspect > imageAspect ? geo.size.height : geo.size.width / imageAspect
                    
                    let offsetX = (geo.size.width - actualWidth) / 2
                    let offsetY = (geo.size.height - actualHeight) / 2

                    let w = actualWidth * region.size.width
                    let h = actualHeight * region.size.height
                    let x = offsetX + (actualWidth * region.center.x)
                    let y = offsetY + (actualHeight * region.center.y)
                    
                    let isSelected = tappedArea == region.area

                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.35) : Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.blue.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        )
                        .overlay(
                            Text(region.label)
                                .font(.caption2.bold())
                                .foregroundColor(isSelected ? .white : .blue)
                        )
                        .contentShape(Rectangle())
                        .frame(width: w, height: h)
                        .position(x: x, y: y)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                tappedArea = region.area
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSelect(region.area)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
