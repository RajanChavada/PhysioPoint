import Foundation
import Combine

/// Legacy ScheduleService — now delegates to StorageService.
/// Kept for backward compatibility; all scheduling logic lives in StorageService.

protocol ScheduleServiceProtocol {
    func markSlotCompleted(_ slotID: UUID)
}

class ScheduleService: ObservableObject, ScheduleServiceProtocol {
    private let storage: StorageService

    init(storage: StorageService = StorageService()) {
        self.storage = storage
    }

    func markSlotCompleted(_ slotID: UUID) {
        storage.markSlotComplete(slotID)
    }
}
