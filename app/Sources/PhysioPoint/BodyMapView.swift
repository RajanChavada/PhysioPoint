import SwiftUI

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
                    // We need to keep the image centered, so we track its actual aspect ratio layout
                    // To do this simply, we will use a ZStack that fits the same bounding box
                    // and places the rects.

                ForEach(normalizedRegions) { region in
                    // In a default scaledToFit, the image will preserve its aspect ratio
                    // and either width or height will be maxed out.
                    // Assuming the image is roughly 1:2 aspect ratio (portrait)
                    // Let's use the full geometry bounds as the coordinate space for now
                    // as per the UI guide. Just be aware if the image is way off aspect, 
                    // it might have padding on sides or top.
                    
                    let imageAspect: CGFloat = 1.0 / 2.0 // rough estimate from guide 250x500
                    let viewAspect = geo.size.width / geo.size.height
                    
                    var actualWidth = geo.size.width
                    var actualHeight = geo.size.height
                    
                    if viewAspect > imageAspect {
                        // View is wider than image. Height applies, width is padded.
                        actualWidth = geo.size.height * imageAspect
                    } else {
                        // View is taller than image. Width applies, height is padded.
                        actualHeight = geo.size.width / imageAspect
                    }
                    
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
