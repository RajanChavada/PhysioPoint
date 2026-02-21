import Foundation
import Combine

protocol ScheduleServiceProtocol {
    func todaysPlan(for exercise: Exercise) -> DailyPlan
    func markSlotCompleted(_ slotID: UUID)
    var currentPlan: DailyPlan { get }
}

class ScheduleService: ObservableObject, ScheduleServiceProtocol {
    @Published var currentPlan: DailyPlan
    private let storage: StorageService
    
    init(storage: StorageService = StorageService()) {
        self.storage = storage
        
        if let stored = storage.loadDailyPlan(), Calendar.current.isDateInToday(stored.date) {
            self.currentPlan = stored
        } else {
            // Default empty plan if none stored for today
            self.currentPlan = DailyPlan(date: Date(), slots: [])
        }
    }
    
    func todaysPlan(for exercise: Exercise) -> DailyPlan {
        if !currentPlan.slots.isEmpty && Calendar.current.isDateInToday(currentPlan.date) {
            // Check if the plan matches the exercise if necessary, but we'll assume it's valid for this demo path.
            return currentPlan
        }
        
        // Generate a new plan: Same exercise 3 times per day for demo
        let newPlan = DailyPlan(date: Date(), slots: [
            PlanSlot(id: UUID(), label: "Morning", exerciseID: exercise.id, isCompleted: false),
            PlanSlot(id: UUID(), label: "Afternoon", exerciseID: exercise.id, isCompleted: false),
            PlanSlot(id: UUID(), label: "Evening", exerciseID: exercise.id, isCompleted: false)
        ])
        
        self.currentPlan = newPlan
        storage.saveDailyPlan(newPlan)
        
        return newPlan
    }
    
    func markSlotCompleted(_ slotID: UUID) {
        if let index = currentPlan.slots.firstIndex(where: { $0.id == slotID }) {
            currentPlan.slots[index].isCompleted = true
            storage.saveDailyPlan(currentPlan)
            
            // NOTE: For the Swift Student Challenge demo, persistence resets might happen.
            // In a full production app with robust notifications, we would also:
            // clear the UNUserNotificationCenter alarm for this specific slot ID here.
        }
    }
}
