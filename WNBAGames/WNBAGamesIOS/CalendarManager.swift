import Foundation
import EventKit

@MainActor
final class CalendarManager {
    static let shared = CalendarManager()

    private let store = EKEventStore()

    enum AddResult {
        case added
        case denied
        case failed(String)
    }

    func add(_ game: Game) async -> AddResult {
        let granted: Bool
        do {
            if #available(iOS 17.0, *) {
                granted = try await store.requestWriteOnlyAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
        } catch {
            return .failed(error.localizedDescription)
        }

        guard granted else { return .denied }

        let event = EKEvent(eventStore: store)
        event.title = "\(game.awayTeam.displayName) at \(game.homeTeam.displayName)"
        event.startDate = game.date
        event.endDate = game.date.addingTimeInterval(2.5 * 3600)
        if let venue = game.venueName {
            event.location = [venue, game.venueCity].compactMap { $0 }.joined(separator: ", ")
        }
        if !game.networks.isEmpty {
            let nets = game.networks.map { $0.displayName }.joined(separator: ", ")
            event.notes = "Watch: \(nets)"
        }
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            return .added
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
