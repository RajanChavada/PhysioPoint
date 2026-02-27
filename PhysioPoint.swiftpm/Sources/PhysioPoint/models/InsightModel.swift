import SwiftUI
import Foundation

// MARK: - Insight Category

enum InsightCategory {
    case motivation, progress, science, encouragement
    
    var tint: Color {
        switch self {
        case .motivation:    return .orange
        case .progress:      return PPColor.vitalityTeal
        case .science:       return PPColor.actionBlue
        case .encouragement: return PPColor.recoveryIndigo
        }
    }
}

// MARK: - Insight Card

struct InsightCard: Identifiable {
    let id = UUID()
    let category: InsightCategory
    let icon: String
    let headline: String
    let body: String
    let source: String?
    var isContextual: Bool = false
}

// MARK: - Insight Library

struct InsightLibrary {
    
    // 🔥 Motivation & Adherence
    static let motivationCards: [InsightCard] = [
        InsightCard(
            category: .motivation,
            icon: "flame.fill",
            headline: "Showing up is 80% of recovery",
            body: "People who complete even 2 of 3 daily sessions recover 40% faster than those who skip entirely. You're on track.",
            source: "JMIR Rehabilitation, 2022"
        ),
        InsightCard(
            category: .motivation,
            icon: "chart.line.uptrend.xyaxis",
            headline: "Your streak matters more than perfection",
            body: "Patients who stayed consistent for 3+ weeks reported 25% better functional recovery vs. those who caught up in bursts.",
            source: "Washington University School of Medicine, 2022"
        ),
        InsightCard(
            category: .motivation,
            icon: "figure.walk.motion",
            headline: "Most people quit at week 2",
            body: "7 in 10 PT patients don't complete their full program. Every session you finish puts you ahead of the majority.",
            source: "MedBridge Patient Retention Data, 2024"
        ),
        InsightCard(
            category: .motivation,
            icon: "brain.head.profile",
            headline: "Understanding your injury = faster healing",
            body: "Patients who understand their diagnosis adhere to treatment plans 41% better. That's why the Learn tab exists.",
            source: "Beaming Health PT Statistics, 2025"
        )
    ]
    
    // 🧠 Recovery Science (Educational)
    static let scienceCards: [InsightCard] = [
        InsightCard(
            category: .science,
            icon: "clock.arrow.2.circlepath",
            headline: "Why 3 sessions a day?",
            body: "Morning, afternoon, and evening spacing allows muscles to recover between loads while maintaining neuromotor memory — the same protocol used in clinical PT.",
            source: "Clinical Orthopaedic Rehabilitation"
        ),
        InsightCard(
            category: .science,
            icon: "hourglass",
            headline: "The 72-hour rule",
            body: "Soft tissue injuries need 48–72 hours between intense sessions for collagen remodeling. Rest days are prescribed for a reason — they're part of the plan.",
            source: "Journal of Athletic Training"
        ),
        InsightCard(
            category: .science,
            icon: "angle",
            headline: "Why angles matter",
            body: "Moving through the full prescribed range activates all muscle fibers across the movement arc. Partial reps only train part of the tissue, leaving gaps in strength.",
            source: "American Physical Therapy Association"
        ),
        InsightCard(
            category: .science,
            icon: "exclamationmark.triangle.fill",
            headline: "Pain vs. discomfort",
            body: "Mild discomfort during stretching is normal and productive. Sharp or shooting pain means stop immediately. PhysioPoint's AR alerts you when you're in a risky zone.",
            source: "World Physiotherapy"
        ),
        InsightCard(
            category: .science,
            icon: "calendar.badge.clock",
            headline: "The 6-week threshold",
            body: "Most soft tissue injuries show measurable structural healing at 6 weeks. Your timeline in the app is built around this biological window.",
            source: "BMJ Open Sport & Exercise Medicine"
        )
    ]
    
    // 🤝 Encouragement (People-First copy)
    static let encouragementCards: [InsightCard] = [
        InsightCard(
            category: .encouragement,
            icon: "hand.raised.fill",
            headline: "Your helper tip for today",
            body: "For shoulder sessions: ask someone to gently hold your elbow in place — it isolates the rotator cuff and reduces compensatory movement by up to 30%.",
            source: nil
        ),
        InsightCard(
            category: .encouragement,
            icon: "leaf.fill",
            headline: "Small wins compound",
            body: "Recovery isn't linear. Even days where movement feels harder are building tissue resilience. The AR data doesn't lie — your body is adapting.",
            source: nil
        ),
        InsightCard(
            category: .encouragement,
            icon: "sparkles",
            headline: "Listen to your body",
            body: "Some days you'll have more energy than others. If you're feeling fatigued, focus on form over speed. Quality movement > quantity.",
            source: nil
        )
    ]
    
    // 📈 Progress-Aware (Dynamic)
    static func progressCards(completedToday: Int, totalToday: Int, bodyArea: String) -> [InsightCard] {
        var cards: [InsightCard] = []
        
        if completedToday > 0 {
            cards.append(InsightCard(
                category: .progress,
                icon: "checkmark.circle.fill",
                headline: "Great start today",
                body: "You've completed \(completedToday) out of \(totalToday) sessions today. Consistency above 80% accelerates tissue remodeling.",
                source: "Clinical Data Mode",
                isContextual: true
            ))
        }
        
        if completedToday == totalToday && totalToday > 0 {
            cards.append(InsightCard(
                category: .progress,
                icon: "star.fill",
                headline: "Daily Goal Achieved",
                body: "You hit 100% of your prescribed \(bodyArea.lowercased()) exercises today. Rest up, your muscles need time to recover and rebuild.",
                source: "PhysioPoint Tracker",
                isContextual: true
            ))
        }
        
        return cards
    }
    
    // MARK: - Smart Selection Logic
    
    static func selectCards(storage: StorageService) -> [InsightCard] {
        var selected: [InsightCard] = []
        
        let completed = storage.completedSlotCount
        let total = storage.totalSlotCount
        let remaining = total - completed
        
        // Find primary area by looking at the first plan
        let primaryArea = storage.dailyPlans.first?.bodyArea ?? "Knee"
        
        // 1. Always lead with progress if they completed a session today
        if completed > 0 {
            if let pCard = progressCards(completedToday: completed, totalToday: total, bodyArea: primaryArea).randomElement() {
                selected.append(pCard)
            }
        }
        
        // 2. Motivate if they haven't started yet and it's past 10am
        let hour = Calendar.current.component(.hour, from: Date())
        if completed == 0 && remaining > 0 && hour >= 10 {
            if let mCard = motivationCards.randomElement() {
                selected.append(mCard)
            }
        } else if remaining > 0 && selected.isEmpty {
            // Guarantee at least one motivation if no progress
            if let mCard = motivationCards.randomElement() {
                selected.append(mCard)
            }
        }
        
        // 3. Science card
        if let sCard = scienceCards.randomElement() {
            selected.append(sCard)
        }
        
        // 4. Always end with an encouragement card
        if let eCard = encouragementCards.randomElement() {
            selected.append(eCard)
        }
        
        return selected
    }
}
