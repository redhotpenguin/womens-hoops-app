import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let storageKey = "scheduledGameReminders"
    @Published private(set) var scheduledIDs: Set<String> = []

    private init() {
        let raw = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        scheduledIDs = Set(raw)
    }

    func isScheduled(_ gameID: String) -> Bool {
        scheduledIDs.contains(gameID)
    }

    func toggle(for game: Game) async {
        if scheduledIDs.contains(game.id) {
            await unschedule(game)
        } else {
            await schedule(game)
        }
    }

    private func schedule(_ game: Game) async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }
        } catch {
            return
        }

        let fireDate = game.date.addingTimeInterval(-3600)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Tip-off in 1 hour"
        content.body = "\(game.awayTeam.displayName) at \(game.homeTeam.displayName)"
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: game.id),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            scheduledIDs.insert(game.id)
            persist()
        } catch {
            return
        }
    }

    private func unschedule(_ game: Game) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier(for: game.id)]
        )
        scheduledIDs.remove(game.id)
        persist()
    }

    private func identifier(for gameID: String) -> String {
        "game-reminder-\(gameID)"
    }

    private func persist() {
        UserDefaults.standard.set(Array(scheduledIDs), forKey: storageKey)
    }
}
