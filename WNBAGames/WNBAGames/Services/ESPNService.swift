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

        let homeESPN = competition.competitors.first { $0.homeAway == "home" }?.team
        let awayESPN = competition.competitors.first { $0.homeAway == "away" }?.team
        guard let homeESPN, let awayESPN else { return nil }

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
            status: GameStatus.from(competition.status.type.name)
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
