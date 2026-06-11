import Foundation
import SwiftUI

enum ESPNServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        }
    }
}

actor ESPNService {
    static let shared = ESPNService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
    }

    // ESPN's date-range scoreboard endpoint is CDN-cached inconsistently and often
    // returns an empty events array. Per-day queries are always stable, so we fetch
    // the next `windowDays` days in parallel and combine the results.
    func fetchUpcomingGames(limit: Int = 10) async throws -> [Game] {
        let windowDays = 14
        let dates = upcomingDates(count: windowDays)

        var allEvents: [ESPNEvent] = []

        try await withThrowingTaskGroup(of: [ESPNEvent].self) { group in
            for dateStr in dates {
                group.addTask { try await self.fetchDay(dateStr) }
            }
            for try await events in group {
                allEvents.append(contentsOf: events)
            }
        }

        return allEvents
            .compactMap { mapEvent($0) }
            .filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }

    private func fetchDay(_ dateStr: String) async throws -> [ESPNEvent] {
        guard let url = URL(string:
            "https://site.api.espn.com/apis/site/v2/sports/basketball/wnba/scoreboard?dates=\(dateStr)"
        ) else { return [] }

        let data: Data
        do {
            let (responseData, _) = try await session.data(from: url)
            data = responseData
        } catch {
            throw ESPNServiceError.networkError(error)
        }

        do {
            let decoded = try JSONDecoder().decode(ESPNScoreboardResponse.self, from: data)
            return decoded.events
        } catch {
            return []
        }
    }

    private func upcomingDates(count: Int) -> [String] {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")!
        let cal = Calendar.current
        return (0..<count).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: Date()).map { f.string(from: $0) }
        }
    }

    private func parseESPNDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: str) { return date }
        // ESPN omits seconds (e.g. "T23:00Z"); insert ":00" before the timezone token
        var normalized = str
        if let range = normalized.range(of: #"T\d{2}:\d{2}(?=[Z+\-])"#, options: .regularExpression) {
            normalized.insert(contentsOf: ":00", at: range.upperBound)
        }
        return formatter.date(from: normalized)
    }

    private func mapEvent(_ event: ESPNEvent) -> Game? {
        guard let competition = event.competitions.first else { return nil }

        guard let date = parseESPNDate(event.date) else { return nil }

        let homeCompetitor = competition.competitors.first { $0.homeAway == "home" }
        let awayCompetitor = competition.competitors.first { $0.homeAway == "away" }
        guard let homeESPN = homeCompetitor?.team, let awayESPN = awayCompetitor?.team else { return nil }

        let networks: [BroadcastNetwork] = (competition.broadcasts ?? [])
            .flatMap { $0.names }
            .map { BroadcastNetwork.from(apiName: $0) }
            .filter { $0 != .unknown }

        let venueCity: String? = {
            let parts = [competition.venue?.address?.city, competition.venue?.address?.state]
                .compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }()

        return Game(
            id: event.id,
            date: date,
            homeTeam: mapTeam(homeESPN),
            awayTeam: mapTeam(awayESPN),
            venueName: competition.venue?.fullName,
            venueCity: venueCity,
            networks: networks,
            status: GameStatus.from(competition.status.type.name),
            homeScore: homeCompetitor?.score,
            awayScore: awayCompetitor?.score,
            period: competition.status.period,
            displayClock: competition.status.displayClock
        )
    }

    // Fetch all games (past + future) in the 14-day window — used for team detail recent results.
    func fetchAllRecentAndUpcoming(daysBack: Int = 14, daysForward: Int = 14) async throws -> [Game] {
        let dates = surroundingDates(back: daysBack, forward: daysForward)
        var allEvents: [ESPNEvent] = []
        try await withThrowingTaskGroup(of: [ESPNEvent].self) { group in
            for dateStr in dates {
                group.addTask { try await self.fetchDay(dateStr) }
            }
            for try await events in group {
                allEvents.append(contentsOf: events)
            }
        }
        return allEvents
            .compactMap { mapEvent($0) }
            .sorted { $0.date < $1.date }
    }

    private func surroundingDates(back: Int, forward: Int) -> [String] {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")!
        let cal = Calendar.current
        return (-back...forward).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: Date()).map { f.string(from: $0) }
        }
    }

    // Re-fetch a single game by re-pulling its date and finding the matching event.
    // Used by the detail page for live-score polling.
    func refreshGame(id: String, on date: Date) async throws -> Game? {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")!
        let events = try await fetchDay(f.string(from: date))
        return events.first(where: { $0.id == id }).flatMap(mapEvent)
    }

    func fetchStandings() async throws -> [Conference] {
        guard let url = URL(string:
            "https://site.api.espn.com/apis/v2/sports/basketball/wnba/standings"
        ) else {
            throw ESPNServiceError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await session.data(from: url)
            data = responseData
        } catch {
            throw ESPNServiceError.networkError(error)
        }

        let decoded: ESPNStandingsResponse
        do {
            decoded = try JSONDecoder().decode(ESPNStandingsResponse.self, from: data)
        } catch {
            throw ESPNServiceError.decodingError(error)
        }

        guard let children = decoded.children else { return [] }

        return children.map { conference in
            let standings = conference.standings.entries.compactMap { mapStandingsEntry($0) }
            return Conference(name: conference.name, standings: standings)
        }
    }

    func fetchLeaders() async throws -> [LeaderCategory] {
        let year = Calendar.current.component(.year, from: Date())
        // Walk back a year if early in the offseason and current-year fetch is empty.
        for candidateYear in [year, year - 1] {
            if let result = try? await fetchLeadersForYear(candidateYear), !result.isEmpty {
                return result
            }
        }
        return []
    }

    private func fetchLeadersForYear(_ year: Int) async throws -> [LeaderCategory] {
        let urlString = "https://sports.core.api.espn.com/v2/sports/basketball/leagues/wnba/seasons/\(year)/types/2/leaders?lang=en&region=us"
        guard let url = URL(string: urlString) else {
            throw ESPNServiceError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await session.data(from: url)
            data = responseData
        } catch {
            throw ESPNServiceError.networkError(error)
        }

        let decoded: ESPNLeadersResponse
        do {
            decoded = try JSONDecoder().decode(ESPNLeadersResponse.self, from: data)
        } catch {
            throw ESPNServiceError.decodingError(error)
        }

        let interesting: [String: String] = [
            "pointsPerGame": "Points",
            "reboundsPerGame": "Rebounds",
            "assistsPerGame": "Assists",
            "stealsPerGame": "Steals",
            "blocksPerGame": "Blocks"
        ]

        let categories = (decoded.categories ?? []).filter { interesting[$0.name] != nil }

        var resolved: [LeaderCategory] = []
        try await withThrowingTaskGroup(of: LeaderCategory?.self) { group in
            for cat in categories {
                let display = interesting[cat.name] ?? cat.displayName ?? cat.name
                group.addTask {
                    let entries = (cat.leaders ?? []).prefix(20)
                    var leaders: [Leader] = []
                    for entry in entries {
                        let athleteName = await self.fetchAthleteName(entry.athlete?.ref)
                        let teamAbbr = await self.fetchTeamAbbreviation(entry.team?.ref)
                        let value = entry.displayValue ?? (entry.value.map { String(format: "%.1f", $0) } ?? "—")
                        leaders.append(Leader(
                            athleteName: athleteName ?? "Unknown",
                            teamAbbreviation: teamAbbr,
                            displayValue: value,
                            value: entry.value
                        ))
                    }
                    return LeaderCategory(key: cat.name, displayName: display, leaders: leaders)
                }
            }
            for try await cat in group {
                if let cat { resolved.append(cat) }
            }
        }

        let order = ["pointsPerGame", "reboundsPerGame", "assistsPerGame", "stealsPerGame", "blocksPerGame"]
        return resolved.sorted { a, b in
            (order.firstIndex(of: a.key) ?? .max) < (order.firstIndex(of: b.key) ?? .max)
        }
    }

    private func fetchAthleteName(_ ref: String?) async -> String? {
        guard let ref, let url = httpsURL(from: ref) else { return nil }
        guard let (data, _) = try? await session.data(from: url) else { return nil }
        let decoded = try? JSONDecoder().decode(ESPNAthleteDetail.self, from: data)
        return decoded?.displayName ?? decoded?.shortName
    }

    private func fetchTeamAbbreviation(_ ref: String?) async -> String? {
        guard let ref, let url = httpsURL(from: ref) else { return nil }
        guard let (data, _) = try? await session.data(from: url) else { return nil }
        let decoded = try? JSONDecoder().decode(ESPNTeamDetail.self, from: data)
        return decoded?.abbreviation
    }

    private func httpsURL(from ref: String) -> URL? {
        // ESPN $refs come back as http://... — upgrade to https for ATS.
        let upgraded = ref.replacingOccurrences(of: "http://", with: "https://")
        return URL(string: upgraded)
    }

    private func mapStandingsEntry(_ entry: ESPNStandingsEntry) -> Standing? {
        let team = mapTeam(entry.team)
        let wins = entry.stats.first(where: { $0.name == "wins" })?.value.map(Int.init) ?? 0
        let losses = entry.stats.first(where: { $0.name == "losses" })?.value.map(Int.init) ?? 0
        let winPercent = entry.stats.first(where: { $0.name == "winPercent" })?.value
        let gamesBehind = entry.stats.first(where: { $0.name == "gamesBehind" })?.value
        return Standing(
            team: team,
            wins: wins,
            losses: losses,
            winPercent: winPercent,
            gamesBehind: gamesBehind
        )
    }

    private func mapTeam(_ t: ESPNTeam) -> Team {
        Team(
            id: t.id ?? t.abbreviation,
            displayName: t.displayName,
            abbreviation: t.abbreviation,
            primaryColor: t.color.flatMap { Color(hex: $0) }
        )
    }
}
