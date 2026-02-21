import SwiftUI

// MARK: - Body Region Data

struct NormalizedBodyRegion: Identifiable {
    let id = UUID()
    let area: BodyArea
    let label: String
    let center: CGPoint  // normalized 0...1 within the body image bounds
    let radius: CGFloat  // normalized radius relative to image width
}

/// Five tappable zones: shoulders, elbows, hips, knees, ankles
/// Positions tuned for a front-facing outline body PNG.
let bodyRegions: [NormalizedBodyRegion] = [
    NormalizedBodyRegion(
        area: .shoulder,
        label: "Shoulders",
        center: CGPoint(x: 0.50, y: 0.19),
        radius: 0.14
    ),
    NormalizedBodyRegion(
        area: .elbow,
        label: "Elbows",
        center: CGPoint(x: 0.50, y: 0.38),
        radius: 0.10
    ),
    NormalizedBodyRegion(
        area: .hip,
        label: "Hips",
        center: CGPoint(x: 0.50, y: 0.48),
        radius: 0.12
    ),
    NormalizedBodyRegion(
        area: .knee,
        label: "Knees",
        center: CGPoint(x: 0.50, y: 0.66),
        radius: 0.10
    ),
    NormalizedBodyRegion(
        area: .ankle,
        label: "Ankles",
        center: CGPoint(x: 0.50, y: 0.87),
        radius: 0.08
    ),
]

// MARK: - Adaptive Body Map View

struct AdaptiveBodyMapView: View {
    let onSelect: (BodyArea) -> Void
    @State private var tappedArea: BodyArea? = nil

    var body: some View {
        GeometryReader { geo in
            let imageAspect: CGFloat = 0.45
            let viewAspect = geo.size.width / geo.size.height

            let imgW = viewAspect > imageAspect ? geo.size.height * imageAspect : geo.size.width
            let imgH = viewAspect > imageAspect ? geo.size.height : geo.size.width / imageAspect
            let offX = (geo.size.width - imgW) / 2
            let offY = (geo.size.height - imgH) / 2

            ZStack {
                // Body silhouette — transparent-bg outline image
                BundledImage("body_front", maxHeight: imgH)
                    .frame(width: imgW, height: imgH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .opacity(0.55)

                // Tappable zone circles
                ForEach(bodyRegions) { region in
                    let cx = offX + imgW * region.center.x
                    let cy = offY + imgH * region.center.y
                    let r  = imgW * region.radius
                    let isSelected = tappedArea == region.area

                    ZStack {
                        // Glow behind selected circle
                        if isSelected {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [PPColor.vitalityTeal.opacity(0.45), PPColor.vitalityTeal.opacity(0)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: r * 1.4
                                    )
                                )
                                .frame(width: r * 3.0, height: r * 3.0)
                                .transition(.scale.combined(with: .opacity))
                        }

                        // The circle itself
                        Circle()
                            .fill(
                                isSelected
                                    ? PPColor.vitalityTeal.opacity(0.25)
                                    : PPColor.actionBlue.opacity(0.06)
                            )
                            .frame(width: r * 2, height: r * 2)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? PPColor.vitalityTeal : PPColor.actionBlue.opacity(0.25),
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                            .overlay(
                                // Checkmark when selected, label when not
                                Group {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: r * 0.5, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Text(region.label)
                                            .font(.system(size: max(r * 0.3, 9), weight: .medium))
                                            .foregroundColor(PPColor.actionBlue.opacity(0.7))
                                            .minimumScaleFactor(0.5)
                                    }
                                }
                            )
                    }
                    .contentShape(Circle())
                    .position(x: cx, y: cy)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            tappedArea = region.area
                        }
                        onSelect(region.area)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
