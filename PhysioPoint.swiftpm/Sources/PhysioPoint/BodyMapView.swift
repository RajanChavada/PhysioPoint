import SwiftUI

enum BodyPart: String, CaseIterable, Identifiable {
    case head, shoulders, knees, feet
    var id: String { rawValue }
}

struct NormalizedBodyRegion: Identifiable {
    let id = UUID()
    let kind: BodyPart
    let center: CGPoint  // x, y in 0.0...1.0
    let size: CGSize     // width, height in 0.0...1.0
}

let normalizedRegions: [NormalizedBodyRegion] = [
    NormalizedBodyRegion(
        kind: .head,
        center: CGPoint(x: 0.5, y: 0.12),
        size: CGSize(width: 0.32, height: 0.16)
    ),
    NormalizedBodyRegion(
        kind: .shoulders,
        center: CGPoint(x: 0.5, y: 0.26),
        size: CGSize(width: 0.8, height: 0.12)
    ),
    NormalizedBodyRegion(
        kind: .knees,
        center: CGPoint(x: 0.5, y: 0.70),
        size: CGSize(width: 0.48, height: 0.12)
    ),
    NormalizedBodyRegion(
        kind: .feet,
        center: CGPoint(x: 0.5, y: 0.88),
        size: CGSize(width: 0.48, height: 0.16)
    )
]

struct AdaptiveBodyMapView: View {
    let onSelect: (BodyPart) -> Void
    @State private var hoveredPart: BodyPart? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("front-facing")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                ForEach(normalizedRegions) { region in
                    let viewAspect = geo.size.width / geo.size.height
                    let imageAspect: CGFloat = 1.0 / 2.0 
                    
                    let actualWidth = viewAspect > imageAspect ? geo.size.height * imageAspect : geo.size.width
                    let actualHeight = viewAspect > imageAspect ? geo.size.height : geo.size.width / imageAspect
                    
                    let offsetX = (geo.size.width - actualWidth) / 2
                    let offsetY = (geo.size.height - actualHeight) / 2

                    let width = actualWidth * region.size.width
                    let height = actualHeight * region.size.height
                    let x = offsetX + (actualWidth * region.center.x)
                    let y = offsetY + (actualHeight * region.center.y)

                    Rectangle()
                        .fill(hoveredPart == region.kind ? Color.blue.opacity(0.3) : Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: width, height: height)
                        .position(x: x, y: y)
                        .onTapGesture {
                            onSelect(region.kind)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
