import SwiftUI

struct TeamDetailView: View {
    let team: Team
    @StateObject private var loader = TeamGamesLoader()

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Circle()
                        .fill(team.primaryColor ?? Color.secondary.opacity(0.5))
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading) {
                        Text(team.displayName)
                            .font(.title3.weight(.semibold))
                        Text(team.abbreviation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let url = team.websiteURL {
                        Link(destination: url) {
                            Image(systemName: "globe")
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Upcoming") {
                if loader.upcoming.isEmpty {
                    if loader.isLoading {
                        ProgressView()
                    } else {
                        Text("No upcoming games in the next 2 weeks.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(loader.upcoming) { game in
                        GameRowView(game: game)
                    }
                }
            }

            Section("Recent") {
                if loader.recent.isEmpty {
                    if loader.isLoading {
                        ProgressView()
                    } else {
                        Text("No recent results.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(loader.recent) { game in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(game.awayTeam.abbreviation) \(game.awayScore ?? "—")")
                                Text("@")
                                    .foregroundStyle(.secondary)
                                Text("\(game.homeTeam.abbreviation) \(game.homeScore ?? "—")")
                                Spacer()
                                if let line = game.statusLine {
                                    Text(line)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(game.formattedDate)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(team.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loader.load(for: team) }
        .refreshable { await loader.load(for: team) }
    }
}

@MainActor
final class TeamGamesLoader: ObservableObject {
    @Published var upcoming: [Game] = []
    @Published var recent: [Game] = []
    @Published var isLoading = false

    private let service: ESPNService

    init(service: ESPNService = .shared) {
        self.service = service
    }

    func load(for team: Team) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let games = try await service.fetchAllRecentAndUpcoming()
            let mine = games.filter {
                $0.homeTeam.id == team.id || $0.awayTeam.id == team.id
            }
            let now = Date()
            upcoming = mine.filter { $0.date >= now }
            let past = mine.filter { $0.date < now && $0.isFinal }
            let sortedPast = past.sorted { $0.date > $1.date }
            recent = Array(sortedPast.prefix(5))
        } catch {
            // Leave arrays as-is on error; could surface a message later.
        }
    }
}
