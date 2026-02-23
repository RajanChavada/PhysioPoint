import Foundation

// MARK: - Language Helper

/// Translates clinical/medical terms into plain English
/// so the app is accessible to elderly users and non-clinicians.
enum LanguageHelper {

    /// Clinical → Plain English glossary
    private static let glossary: [String: String] = [
        "ROM Recovery": "Getting moving again",
        "Range of motion": "How far you can move",
        "Angle-based tracking": "Camera watches your movement",
        "Progressive bending": "Slowly bending more each day",
        "Quad sets": "Tighten your thigh muscles",
        "Flexion": "Bending",
        "Extension": "Straightening",
        "Impingement": "Pinching pain",
        "Bilateral": "Both sides",
        "Load the joint": "Put weight on it",
        "Immobilization": "Keeping still to heal",
        "Dorsiflexion": "Pulling toes toward you",
        "Scapular": "Shoulder blade",
        "Rotator cuff": "Shoulder muscles",
        "RICE Phase": "Rest, Ice, Compress, Elevate",
        "AR Tracked": "Camera tracks your movement",
        "Angle-Based": "Camera watches your movement",
    ]

    /// Look up a plain-English replacement for a clinical term.
    static func plainEnglish(for term: String) -> String {
        glossary[term] ?? term
    }

    /// Replace all known clinical terms in a string with plain English.
    static func simplify(_ text: String) -> String {
        var result = text
        for (clinical, plain) in glossary {
            result = result.replacingOccurrences(of: clinical, with: plain, options: .caseInsensitive)
        }
        return result
    }
}
