import Foundation
import Combine

struct ActivityEvent: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let date: Date
}

final class ActivityStore: ObservableObject {

    static let shared = ActivityStore()

    @Published private(set) var events: [ActivityEvent] = []

    private init() {}

    func addEvent(
        icon: String,
        title: String,
        detail: String
    ) {

        let event = ActivityEvent(
            icon: icon,
            title: title,
            detail: detail,
            date: Date()
        )

        events.insert(
            event,
            at: 0
        )
    }

    func clearEvents() {
        events.removeAll()
    }
}
