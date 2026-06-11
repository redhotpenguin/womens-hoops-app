import SwiftUI

struct Game: Identifiable, Hashable {
    let id: String
    let date: Date
    let homeTeam: Team
    let awayTeam: Team
    let venueName: String?
    let venueCity: String?
    let networks: [BroadcastNetwork]
    let status: GameStatus

    static func == (lhs: Game, rhs: Game) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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
        let time = f.string(from: date)
        let tz = TimeZone.current.abbreviation(for: date) ?? ""
        return tz.isEmpty ? time : "\(time) \(tz)"
    }
}

struct Team: Identifiable {
    let id: String
    let displayName: String
    let abbreviation: String
    let primaryColor: Color?

    var websiteURL: URL? {
        let subdomain: String? = switch abbreviation {
        case "ATL": "dream"
        case "CHI": "sky"
        case "CON": "sun"
        case "DAL": "wings"
        case "GS":  "valkyries"
        case "IND": "fever"
        case "LV":  "aces"
        case "LA":  "sparks"
        case "MIN": "lynx"
        case "NY":  "liberty"
        case "PHX": "mercury"
        case "SEA": "storm"
        case "WSH": "mystics"
        default:    nil
        }
        return subdomain.flatMap { URL(string: "https://\($0).wnba.com") }
    }
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
