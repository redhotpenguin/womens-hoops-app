import SwiftUI

enum BroadcastNetwork: String, CaseIterable, Hashable {
    case espn = "ESPN"
    case espnPlus = "ESPN+"
    case abc = "ABC"
    case amazonPrime = "Prime Video"
    case cbs = "CBS"
    case ion = "ION"
    case nbc = "NBC"
    case peacock = "Peacock"
    case usaNetwork = "USA Network"
    case nbaTV = "NBA TV"
    case disneyPlus = "Disney+"
    case wnbaLeaguePass = "WNBA League Pass"
    case unknown = "Unknown"

    static func from(apiName: String) -> BroadcastNetwork {
        let trimmed = apiName.trimmingCharacters(in: .whitespaces)
        if let exact = BroadcastNetwork(rawValue: trimmed) { return exact }
        return fuzzyMatch(trimmed) ?? .unknown
    }

    private static func fuzzyMatch(_ name: String) -> BroadcastNetwork? {
        let lower = name.lowercased()
        if lower.contains("prime") { return .amazonPrime }
        if lower.contains("espn+") || lower.contains("espn plus") { return .espnPlus }
        if lower.contains("espn") { return .espn }
        if lower.contains("peacock") { return .peacock }
        if lower.contains("ion") { return .ion }
        if lower.contains("disney") { return .disneyPlus }
        if lower.contains("usa") { return .usaNetwork }
        if lower.contains("nba tv") { return .nbaTV }
        if lower.contains("nbc") { return .nbc }
        if lower.contains("wnba") { return .wnbaLeaguePass }
        if lower == "abc" { return .abc }
        if lower == "cbs" { return .cbs }
        return nil
    }

    var displayName: String {
        switch self {
        case .espn: return "ESPN"
        case .espnPlus: return "ESPN+"
        case .abc: return "ABC"
        case .amazonPrime: return "Prime"
        case .cbs: return "CBS"
        case .ion: return "ION"
        case .nbc: return "NBC"
        case .peacock: return "Peacock"
        case .usaNetwork: return "USA"
        case .nbaTV: return "NBA TV"
        case .disneyPlus: return "Disney+"
        case .wnbaLeaguePass: return "League Pass"
        case .unknown: return "Unknown"
        }
    }

    var hasAppleTVApp: Bool {
        switch self {
        case .amazonPrime, .espn, .espnPlus, .abc, .disneyPlus, .peacock, .cbs, .nbc, .nbaTV:
            return true
        case .ion, .usaNetwork, .wnbaLeaguePass, .unknown:
            return false
        }
    }

    var watchURL: URL? {
        let base: String? = switch self {
        case .amazonPrime: "https://www.amazon.com/gp/video/storefront"
        case .espn, .espnPlus, .abc: "https://www.espn.com/watch"
        case .cbs: "https://www.paramountplus.com"
        case .peacock, .nbc: "https://www.peacocktv.com"
        case .nbaTV: "https://www.nba.com/watch"
        case .ion: "https://iontelevision.com"
        case .usaNetwork: "https://www.usanetwork.com"
        case .disneyPlus: "https://www.disneyplus.com"
        case .wnbaLeaguePass: "https://leaguepass.wnba.com"
        case .unknown: nil
        }
        return base.flatMap(Self.tagged)
    }

    private static func tagged(_ s: String) -> URL? {
        guard var c = URLComponents(string: s) else { return nil }
        var items = c.queryItems ?? []
        items.append(URLQueryItem(name: "utm_source", value: "wnba_games_app_ios"))
        c.queryItems = items
        return c.url
    }

    var brandColor: Color {
        switch self {
        case .espn, .espnPlus: return Color(red: 0.92, green: 0.11, blue: 0.14)
        case .abc: return Color(red: 0.0, green: 0.31, blue: 0.62)
        case .amazonPrime: return Color(red: 0.0, green: 0.58, blue: 0.83)
        case .cbs: return Color(red: 0.12, green: 0.47, blue: 0.71)
        case .ion: return Color(red: 0.13, green: 0.55, blue: 0.13)
        case .nbc: return Color(red: 0.36, green: 0.20, blue: 0.64)
        case .peacock: return Color(red: 0.0, green: 0.60, blue: 0.40)
        case .usaNetwork: return Color(red: 0.0, green: 0.20, blue: 0.60)
        case .nbaTV: return Color(red: 0.73, green: 0.0, blue: 0.13)
        case .disneyPlus: return Color(red: 0.04, green: 0.16, blue: 0.44)
        case .wnbaLeaguePass: return Color(red: 1.0, green: 0.50, blue: 0.0)
        case .unknown: return Color.secondary
        }
    }
}
