import Foundation

// MARK: - Per-Rep Quality

enum RepQuality: String, Codable {
    case good      // within target range
    case fair      // close but not perfect
    case poor      // out of range
}

struct RepResult: Codable, Identifiable {
    var id: UUID = UUID()
    var repNumber: Int
    var peakAngle: Double
    var timeInTarget: Double  // seconds spent in target zone
    var quality: RepQuality
}

// MARK: - Session Metrics

struct SessionMetrics: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var exerciseID: UUID?
    var bestAngle: Double = 0.0
    var repsCompleted: Int = 0
    var targetReps: Int = 0
    var targetAngleLow: Double = 80      // lower bound of target range
    var targetAngleHigh: Double = 95     // upper bound of target range
    var timeInGoodForm: Double = 0.0     // total seconds in target zone
    var repResults: [RepResult] = []     // per-rep breakdown

    // Comparison with previous session (nil if first session)
    var previousBestAngle: Double? = nil
    var previousTimeInForm: Double? = nil

    // Today's plan progress
    var todayCompleted: Int = 1          // how many exercises done today
    var todayTotal: Int = 3              // total exercises planned today

    // MARK: - Computed Helpers

    var angleDelta: Double? {
        guard let prev = previousBestAngle else { return nil }
        return bestAngle - prev
    }

    var timeDelta: Double? {
        guard let prev = previousTimeInForm else { return nil }
        return timeInGoodForm - prev
    }

    var targetRangeLabel: String {
        "\(Int(targetAngleLow))°–\(Int(targetAngleHigh))°"
    }
}
