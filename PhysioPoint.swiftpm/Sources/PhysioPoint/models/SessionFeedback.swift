import Foundation

// MARK: - SessionFeedback.swift
// Accumulates exercise-specific events during a session.
// Passed from RehabSessionViewModel → SessionMetrics → SummaryView.

public struct SessionFeedback: Codable, Equatable {
    // What the user did well (picked at session end)
    public var positiveObservation: String = ""
    // What they should work on next time
    public var growthObservation: String = ""
    // Recovery journey message tied to the positive
    public var journeyMessage: String = ""
}

// Fired from Coordinator into ViewModel as events occur
public enum SessionEvent: Equatable {
    case goodFormHeld(seconds: Double)         // spent ≥2s in zone continuously
    case cheatDetected(jointName: String)      // secondary joint deviated
    case rangeImproving(percent: Double)       // best angle > previous best
    case consistentMovement                    // low jitter across session
    case roughMovement                         // high jitter
    case fullRangeReached                      // hit upper bound of targetRange
    case rangeShort(gapDegrees: Double)        // never reached target upper bound
}
