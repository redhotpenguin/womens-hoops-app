import Foundation

struct ESPNScoreboardResponse: Codable {
    let events: [ESPNEvent]
}

struct ESPNEvent: Codable {
    let id: String
    let date: String
    let name: String
    let shortName: String
    let competitions: [ESPNCompetition]
}

struct ESPNCompetition: Codable {
    let venue: ESPNVenue?
    let competitors: [ESPNCompetitor]
    let broadcasts: [ESPNBroadcast]?
    let status: ESPNStatus
}

struct ESPNVenue: Codable {
    let fullName: String
    let address: ESPNAddress?
}

struct ESPNAddress: Codable {
    let city: String?
    let state: String?
}

struct ESPNCompetitor: Codable {
    let homeAway: String
    let team: ESPNTeam
    let score: String?
}

struct ESPNTeam: Codable {
    let id: String?
    let displayName: String
    let abbreviation: String
    let color: String?
    let alternateColor: String?
    let logo: String?
}

struct ESPNBroadcast: Codable {
    let names: [String]
    let market: String?

    enum CodingKeys: String, CodingKey {
        case names
        case market
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.names = (try? container.decode([String].self, forKey: .names)) ?? []
        self.market = try? container.decode(String.self, forKey: .market)
    }
}

struct ESPNStatus: Codable {
    let type: ESPNStatusType
    let period: Int?
    let displayClock: String?
}

struct ESPNStatusType: Codable {
    let name: String
    let completed: Bool
}

struct ESPNStandingsResponse: Codable {
    let children: [ESPNStandingsConference]?
}

struct ESPNStandingsConference: Codable {
    let name: String
    let standings: ESPNStandingsBlock
}

struct ESPNStandingsBlock: Codable {
    let entries: [ESPNStandingsEntry]
}

struct ESPNStandingsEntry: Codable {
    let team: ESPNTeam
    let stats: [ESPNStandingsStat]
}

struct ESPNStandingsStat: Codable {
    let name: String
    let value: Double?
    let displayValue: String?
}

struct ESPNLeadersResponse: Codable {
    let categories: [ESPNLeaderCategory]?
}

struct ESPNLeaderCategory: Codable {
    let name: String
    let displayName: String?
    let shortDisplayName: String?
    let leaders: [ESPNLeaderEntry]?
}

struct ESPNLeaderEntry: Codable {
    let displayValue: String?
    let value: Double?
    let athlete: ESPNRef?
    let team: ESPNRef?
}

struct ESPNRef: Codable {
    let ref: String?
    enum CodingKeys: String, CodingKey {
        case ref = "$ref"
    }
}

struct ESPNAthleteDetail: Codable {
    let displayName: String?
    let shortName: String?
}

struct ESPNTeamDetail: Codable {
    let abbreviation: String?
    let displayName: String?
}
