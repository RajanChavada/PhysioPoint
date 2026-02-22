import SwiftUI

// MARK: - Resource Bundle Discovery

/// Resolves the correct resource bundle at runtime.
/// Swift Playgrounds does NOT reliably generate `Bundle.module`,
/// so we search multiple locations.
private let resourceBundle: Bundle = {
    // 1. Check for an SPM-generated resource bundle next to the executable
    let bundleNames = [
        "PhysioPoint_PhysioPoint.bundle",
        "PhysioPoint.bundle"
    ]

    let searchRoots = [
        Bundle.main.bundleURL,
        Bundle.main.resourceURL,
        Bundle(for: _BundleAnchor.self).resourceURL,
        Bundle(for: _BundleAnchor.self).bundleURL
    ].compactMap { $0 }

    for root in searchRoots {
        for name in bundleNames {
            let url = root.appendingPathComponent(name)
            if let b = Bundle(url: url) {
                print("📦 Found resource bundle: \(url.lastPathComponent)")
                return b
            }
        }
    }

    // 2. Fallback — main bundle (Swift Playgrounds often puts resources here directly)
    print("📦 Using Bundle.main as resource bundle")
    return Bundle.main
}()

/// Tiny anchor class so we can locate the bundle that contains our code.
private final class _BundleAnchor {}

// MARK: - BundledImage

/// Loads an image from the SPM resource bundle or main bundle.
/// Shows a light placeholder silhouette if the image cannot be found.
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
        } else {
            // Fallback placeholder so something is visible during debugging
            Image(systemName: "figure.stand")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: maxHeight)
                .foregroundColor(PPColor.actionBlue.opacity(0.15))
                .onAppear {
                    print("⚠️ BundledImage: Could not load '\(name)'. Showing placeholder.")
                    debugBundleContents()
                }
        }
    }

    private func loadImage() -> UIImage? {
        let extensions = ["png", "jpg", "jpeg", nil]

        // Strategy 1: SPM resource bundle
        for ext in extensions {
            if let url = resourceBundle.url(forResource: name, withExtension: ext) {
                if let img = UIImage(contentsOfFile: url.path) {
                    return img
                }
            }
        }

        // Strategy 2: UIImage(named:) — searches asset catalogs + main bundle
        if let img = UIImage(named: name) {
            return img
        }

        // Strategy 3: UIImage(named:in:compatibleWith:) with our resource bundle
        if let img = UIImage(named: name, in: resourceBundle, compatibleWith: nil) {
            return img
        }

        // Strategy 4: Direct file path in main bundle
        for ext in ["png", "jpg"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                if let img = UIImage(contentsOfFile: url.path) {
                    return img
                }
            }
        }

        // Strategy 5: Walk the main bundle looking for the file
        if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            if let items = try? fm.contentsOfDirectory(atPath: resourcePath) {
                for item in items {
                    if item.hasPrefix(name) {
                        let fullPath = (resourcePath as NSString).appendingPathComponent(item)
                        if let img = UIImage(contentsOfFile: fullPath) {
                            print("📦 Found '\(name)' via directory scan: \(item)")
                            return img
                        }
                    }
                }
            }
        }

        // Strategy 6: Walk the resource bundle looking for the file
        if let resourcePath = resourceBundle.resourcePath, resourceBundle != Bundle.main {
            let fm = FileManager.default
            if let items = try? fm.contentsOfDirectory(atPath: resourcePath) {
                for item in items {
                    if item.hasPrefix(name) {
                        let fullPath = (resourcePath as NSString).appendingPathComponent(item)
                        if let img = UIImage(contentsOfFile: fullPath) {
                            print("📦 Found '\(name)' via resource bundle scan: \(item)")
                            return img
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Prints bundle contents to the console for debugging resource issues.
    private func debugBundleContents() {
        print("📦 Resource bundle path: \(resourceBundle.bundlePath)")
        print("📦 Main bundle path: \(Bundle.main.bundlePath)")
        if let rp = resourceBundle.resourcePath,
           let items = try? FileManager.default.contentsOfDirectory(atPath: rp) {
            let imageFiles = items.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") }
            print("📦 Image files in resource bundle (\(imageFiles.count)): \(imageFiles)")
        }
        if let rp = Bundle.main.resourcePath,
           let items = try? FileManager.default.contentsOfDirectory(atPath: rp) {
            let imageFiles = items.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") }
            print("📦 Image files in main bundle (\(imageFiles.count)): \(imageFiles)")
        }
    }
}
