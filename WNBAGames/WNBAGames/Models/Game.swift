import SwiftUI

struct Game: Identifiable {
    let id: String
    let date: Date
    let homeTeam: Team
    let awayTeam: Team
    let venueName: String?
    let venueCity: String?
    let networks: [BroadcastNetwork]
    let status: GameStatus

    var isUpcoming: Bool {
        status == .scheduled && date > Date()
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        f.timeZone = .current
        return f.string(from: date)
    }

    var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.timeZone = .current
        return f.string(from: date)
    }
}

struct Team: Identifiable {
    let id: String
    let displayName: String
    let abbreviation: String
    let primaryColor: Color?
}

enum GameStatus: Equatable {
    case scheduled
    case inProgress
    case final_
    case postponed
    case canceled

    static func from(_ name: String) -> GameStatus {
        switch name {
        case "STATUS_SCHEDULED": return .scheduled
        case "STATUS_IN_PROGRESS": return .inProgress
        case "STATUS_FINAL": return .final_
        case "STATUS_POSTPONED": return .postponed
        case "STATUS_CANCELED": return .canceled
        default: return .scheduled
        }
    }
}
