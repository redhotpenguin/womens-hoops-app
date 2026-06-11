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
    var homeScore: String?
    var awayScore: String?
    var period: Int?
    var displayClock: String?

    static func == (lhs: Game, rhs: Game) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var isUpcoming: Bool {
        status == .scheduled && date > Date()
    }

    var isLive: Bool { status == .inProgress }
    var isFinal: Bool { status == .final_ }

    var statusLine: String? {
        switch status {
        case .inProgress:
            if let period, let displayClock {
                return "Q\(period) · \(displayClock)"
            }
            return "Live"
        case .final_:
            return "Final"
        case .postponed: return "Postponed"
        case .canceled: return "Canceled"
        case .scheduled: return nil
        }
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

struct Team: Identifiable, Hashable {
    let id: String
    let displayName: String
    let abbreviation: String
    let primaryColor: Color?

    static func == (lhs: Team, rhs: Team) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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
