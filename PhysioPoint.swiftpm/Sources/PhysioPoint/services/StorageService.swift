import Foundation

class StorageService: ObservableObject {
    private let defaults = UserDefaults.standard
    private let planKey = "physiopoint_daily_plan"
    private let metricsKey = "physiopoint_recent_metrics"
    
    @Published var recentMetrics: [SessionMetrics] = []
    
    init() {
        self.recentMetrics = loadRecentMetrics()
    }
    
    func saveDailyPlan(_ plan: DailyPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: planKey)
        }
    }
    
    func loadDailyPlan() -> DailyPlan? {
        if let data = defaults.data(forKey: planKey),
           let plan = try? JSONDecoder().decode(DailyPlan.self, from: data) {
            return plan
        }
        return nil
    }
    
    func saveSessionMetrics(_ metrics: SessionMetrics) {
        var allMetrics = loadRecentMetrics()
        allMetrics.append(metrics)
        // Keep only recent 10 sessions for the demo footprint
        if allMetrics.count > 10 {
            allMetrics.removeFirst(allMetrics.count - 10)
        }
        
        if let data = try? JSONEncoder().encode(allMetrics) {
            defaults.set(data, forKey: metricsKey)
        }
        
        DispatchQueue.main.async {
            self.recentMetrics = allMetrics
        }
    }
    
    func loadRecentMetrics() -> [SessionMetrics] {
        if let data = defaults.data(forKey: metricsKey),
           let metrics = try? JSONDecoder().decode([SessionMetrics].self, from: data) {
            return metrics
        }
        return []
    }
}
