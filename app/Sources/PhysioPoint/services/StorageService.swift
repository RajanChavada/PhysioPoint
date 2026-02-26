import Foundation

class StorageService: ObservableObject {
    private let defaults = UserDefaults.standard
    private let plansKey = "physiopoint_daily_plans"
    private let metricsKey = "physiopoint_recent_metrics"

    @Published var dailyPlans: [DailyPlan] = []
    @Published var recentMetrics: [SessionMetrics] = []

    init() {
        self.dailyPlans = loadDailyPlans()
        self.recentMetrics = loadRecentMetrics()
    }

    // MARK: - All Slots (consolidated across plans)

    var allSlots: [PlanSlot] {
        dailyPlans.flatMap(\.slots)
    }

    var totalSlotCount: Int { allSlots.count }

    var completedSlotCount: Int { allSlots.filter(\.isCompleted).count }

    // MARK: - Plans CRUD

    func addPlan(_ plan: DailyPlan) {
        // Remove existing plan for the same condition (replace)
        dailyPlans.removeAll { $0.conditionID == plan.conditionID }
        dailyPlans.append(plan)
        persistPlans()
    }

    func removePlan(conditionID: UUID) {
        dailyPlans.removeAll { $0.conditionID == conditionID }
        persistPlans()
    }

    func plan(for conditionID: UUID) -> DailyPlan? {
        dailyPlans.first { $0.conditionID == conditionID }
    }

    // MARK: - Slot Operations

    func markSlotComplete(_ slotID: UUID) {
        for pi in dailyPlans.indices {
            if let si = dailyPlans[pi].slots.firstIndex(where: { $0.id == slotID }) {
                dailyPlans[pi].slots[si].isCompleted = true
                dailyPlans[pi].slots[si].completedAt = Date()
                persistPlans()
                return
            }
        }
    }

    func unmarkSlotComplete(_ slotID: UUID) {
        for pi in dailyPlans.indices {
            if let si = dailyPlans[pi].slots.firstIndex(where: { $0.id == slotID }) {
                dailyPlans[pi].slots[si].isCompleted = false
                dailyPlans[pi].slots[si].completedAt = nil
                persistPlans()
                return
            }
        }
    }

    func updateSlotHour(_ slotID: UUID, hour: Int) {
        for pi in dailyPlans.indices {
            if let si = dailyPlans[pi].slots.firstIndex(where: { $0.id == slotID }) {
                dailyPlans[pi].slots[si].scheduledHour = hour
                persistPlans()
                return
            }
        }
    }

    // MARK: - Persistence

    private func persistPlans() {
        if let data = try? JSONEncoder().encode(dailyPlans) {
            defaults.set(data, forKey: plansKey)
        }
    }

    private func loadDailyPlans() -> [DailyPlan] {
        guard let data = defaults.data(forKey: plansKey),
              let plans = try? JSONDecoder().decode([DailyPlan].self, from: data)
        else { return [] }
        return plans
    }

    // MARK: - Backward compat: single plan accessor
    // Views that only deal with the current condition's plan can use this

    var dailyPlan: DailyPlan? {
        dailyPlans.first
    }

    func saveDailyPlan(_ plan: DailyPlan) {
        addPlan(plan)
    }

    func loadDailyPlan() -> DailyPlan? {
        dailyPlans.first
    }

    // MARK: - Metrics

    func saveSessionMetrics(_ metrics: SessionMetrics) {
        var all = loadRecentMetrics()
        all.insert(metrics, at: 0)
        all = Array(all.prefix(10))
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: metricsKey)
        }
        DispatchQueue.main.async { self.recentMetrics = all }
    }

    func loadRecentMetrics() -> [SessionMetrics] {
        guard let data = defaults.data(forKey: metricsKey),
              let metrics = try? JSONDecoder().decode([SessionMetrics].self, from: data)
        else { return [] }
        return metrics
    }

    // MARK: - Recovery Pulse Data

    /// Total session count (for blurb engine)
    var sessionCount: Int { recentMetrics.count }

    /// Number of slots completed today
    var todayCompletedCount: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allSlots.filter { slot in
            guard slot.isCompleted, let at = slot.completedAt else { return false }
            return at >= startOfDay
        }.count
    }

    /// Consecutive-day streak with at least 1 completed slot
    var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        while hasCompletedSession(on: date) {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    private func hasCompletedSession(on date: Date) -> Bool {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        return allSlots.contains { slot in
            guard slot.isCompleted, let at = slot.completedAt else { return false }
            return at >= date && at < next
        }
    }

    /// Next incomplete slot across all plans
    func nextIncompleteSlot() -> PlanSlot? {
        allSlots.first { !$0.isCompleted }
    }

    /// Last feeling saved from SummaryView emoji tap
    var lastFeeling: String? {
        get { defaults.string(forKey: "pp_last_feeling") }
        set {
            defaults.set(newValue, forKey: "pp_last_feeling")
            objectWillChange.send()
        }
    }
}
