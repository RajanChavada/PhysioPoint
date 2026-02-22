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
        center: CGPoint(x: 0.50, y: 0.18),
        radius: 0.14
    ),
    NormalizedBodyRegion(
        area: .elbow,
        label: "Elbows",
        center: CGPoint(x: 0.50, y: 0.36),
        radius: 0.10
    ),
    NormalizedBodyRegion(
        area: .hip,
        label: "Hips",
        center: CGPoint(x: 0.50, y: 0.47),
        radius: 0.12
    ),
    NormalizedBodyRegion(
        area: .knee,
        label: "Knees",
        center: CGPoint(x: 0.50, y: 0.65),
        radius: 0.10
    ),
    NormalizedBodyRegion(
        area: .ankle,
        label: "Ankles",
        center: CGPoint(x: 0.50, y: 0.86),
        radius: 0.08
    ),
]

// MARK: - Adaptive Body Map View

struct AdaptiveBodyMapView: View {
    let onSelect: (BodyArea) -> Void
    @State private var tappedArea: BodyArea? = nil

    /// The body image has roughly a 0.45 width-to-height aspect ratio.
    private let imageAspect: CGFloat = 0.45

    var body: some View {
        GeometryReader { geo in
            bodyContent(
                availW: geo.size.width,
                availH: geo.size.height
            )
        }
    }

    // MARK: - Layout Helpers

    private func fittedWidth(_ availW: CGFloat, _ availH: CGFloat) -> CGFloat {
        if availW / max(availH, 1) > imageAspect {
            return availH * imageAspect
        } else {
            return availW
        }
    }

    private func fittedHeight(_ availW: CGFloat, _ availH: CGFloat) -> CGFloat {
        if availW / max(availH, 1) > imageAspect {
            return availH
        } else {
            return availW / imageAspect
        }
    }

    private func offsetX(_ availW: CGFloat, _ availH: CGFloat) -> CGFloat {
        (availW - fittedWidth(availW, availH)) / 2
    }

    private func offsetY(_ availW: CGFloat, _ availH: CGFloat) -> CGFloat {
        (availH - fittedHeight(availW, availH)) / 2
    }

    // MARK: - Body Content

    private func bodyContent(availW: CGFloat, availH: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Body silhouette
            BundledImage("body_front", maxHeight: fittedHeight(availW, availH))
                .frame(width: fittedWidth(availW, availH), height: fittedHeight(availW, availH))
                .clipped()
                .opacity(0.50)
                .offset(x: offsetX(availW, availH), y: offsetY(availW, availH))

            // Tappable zone circles
            ForEach(bodyRegions) { region in
                regionCircle(
                    region: region,
                    fw: fittedWidth(availW, availH),
                    fh: fittedHeight(availW, availH),
                    ox: offsetX(availW, availH),
                    oy: offsetY(availW, availH)
                )
            }
        }
        .frame(width: availW, height: availH)
    }

    // MARK: - Region Circle

    private func regionCircle(region: NormalizedBodyRegion, fw: CGFloat, fh: CGFloat, ox: CGFloat, oy: CGFloat) -> some View {
        ZStack {
            // Glow behind selected circle
            if tappedArea == region.area {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [PPColor.vitalityTeal.opacity(0.45), PPColor.vitalityTeal.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: fw * region.radius * 1.4
                        )
                    )
                    .frame(width: fw * region.radius * 3.0, height: fw * region.radius * 3.0)
                    .transition(.scale.combined(with: .opacity))
            }

            // The circle itself
            Circle()
                .fill(
                    tappedArea == region.area
                        ? PPColor.vitalityTeal.opacity(0.25)
                        : PPColor.actionBlue.opacity(0.06)
                )
                .frame(width: fw * region.radius * 2, height: fw * region.radius * 2)
                .overlay(
                    Circle()
                        .stroke(
                            tappedArea == region.area ? PPColor.vitalityTeal : PPColor.actionBlue.opacity(0.25),
                            lineWidth: tappedArea == region.area ? 2 : 1
                        )
                )
                .overlay(
                    Group {
                        if tappedArea == region.area {
                            Image(systemName: "checkmark")
                                .font(.system(size: fw * region.radius * 0.5, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text(region.label)
                                .font(.system(size: max(fw * region.radius * 0.35, 10), weight: .medium))
                                .foregroundColor(PPColor.actionBlue.opacity(0.7))
                                .minimumScaleFactor(0.5)
                        }
                    }
                )
        }
        .contentShape(Circle())
        .position(
            x: ox + fw * region.center.x,
            y: oy + fh * region.center.y
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                tappedArea = region.area
            }
            onSelect(region.area)
        }
    }
}
