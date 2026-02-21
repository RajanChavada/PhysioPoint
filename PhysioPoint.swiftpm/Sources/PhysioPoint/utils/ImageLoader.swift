import SwiftUI

/// Resolves the SPM resource bundle at runtime without relying on
/// the compiler-generated `Bundle.module` (which Swift Playgrounds
/// on iPad often fails to synthesize).
private let resourceBundle: Bundle = {
    // The SPM-generated resource bundle is named
    // "PhysioPoint_PhysioPoint.bundle" and lives next to the main executable.
    let candidates = [
        // Same directory as the running binary
        Bundle.main.bundleURL,
        // When built with Xcode the bundle is inside .app
        Bundle.main.resourceURL,
        // Fallback to the bundle that contains this source file's class
        Bundle(for: _BundleAnchor.self).resourceURL
    ].compactMap { $0 }

    let bundleNames = [
        "PhysioPoint_PhysioPoint.bundle",
        "PhysioPoint.bundle"
    ]

    for candidate in candidates {
        for name in bundleNames {
            let bundlePath = candidate.appendingPathComponent(name)
            if let bundle = Bundle(url: bundlePath) {
                return bundle
            }
        }
    }
    // Ultimate fallback — use main bundle itself
    return Bundle.main
}()

/// Tiny anchor class so we can locate the bundle that contains our code.
private final class _BundleAnchor {}

// MARK: - BundledImage

/// Loads an image trying the SPM resource bundle first, then the main bundle.
/// Gracefully shows nothing if the image is not found.
struct BundledImage: View {
    let name: String
    let maxHeight: CGFloat

    init(_ name: String, maxHeight: CGFloat = 180) {
        self.name = name
        self.maxHeight = maxHeight
    }

    var body: some View {
        if let img = loadImage() {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: maxHeight)
                .cornerRadius(12)
        }
        // If image not found, show nothing (graceful fallback)
    }

    private func loadImage() -> UIImage? {
        // Try 1: SPM resource bundle with .png extension
        if let url = resourceBundle.url(forResource: name, withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        // Try 2: SPM resource bundle without extension
        if let url = resourceBundle.url(forResource: name, withExtension: nil),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        // Try 3: UIImage(named:) — asset catalogs & main bundle
        if let img = UIImage(named: name) {
            return img
        }
        // Try 4: Main bundle by direct path
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }
}
