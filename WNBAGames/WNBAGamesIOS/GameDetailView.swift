import SwiftUI

struct GameDetailView: View {
    let initialGame: Game

    @State private var game: Game
    @State private var pollTask: Task<Void, Never>? = nil
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.openURL) private var openURL

    init(game: Game) {
        self.initialGame = game
        self._game = State(initialValue: game)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    matchup
                    if let line = game.statusLine {
                        Text(line)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(game.isLive ? .red : .secondary)
                    }
                    Text("\(game.formattedDate) · \(game.formattedTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if game.isUpcoming {
                Section {
                    Button {
                        Task { await notifications.toggle(for: game) }
                    } label: {
                        HStack {
                            Image(systemName: notifications.isScheduled(game.id) ? "bell.fill" : "bell")
                            Text(notifications.isScheduled(game.id)
                                 ? "Reminder set for 1 hour before tip-off"
                                 : "Remind me 1 hour before tip-off")
                            Spacer()
                        }
                    }
                }
            }

            if let venue = game.venueName {
                Section("Venue") {
                    Button {
                        openVenue(name: venue, city: game.venueCity)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(venue)
                                    .foregroundStyle(.primary)
                                if let city = game.venueCity {
                                    Text(city)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "map")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }

            Section("Broadcast") {
                if game.networks.isEmpty {
                    Text("No broadcast announced yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(game.networks, id: \.rawValue) { network in
                        Button {
                            if let url = network.watchURL { openURL(url) }
                        } label: {
                            HStack {
                                NetworkBadgeView(network: network)
                                Text(network.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if network.watchURL != nil {
                                    Image(systemName: "arrow.up.forward.square")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startPollingIfLive() }
        .onDisappear { pollTask?.cancel() }
    }

    private var matchup: some View {
        HStack(spacing: 16) {
            teamColumn(team: game.awayTeam, score: game.awayScore)
            Text("@")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            teamColumn(team: game.homeTeam, score: game.homeScore)
        }
    }

    private func teamColumn(team: Team, score: String?) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(team.primaryColor ?? Color.secondary.opacity(0.5))
                .frame(width: 16, height: 16)
            Text(team.abbreviation)
                .font(.title3.weight(.bold))
            if let score, (game.isLive || game.isFinal) {
                Text(score)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func openVenue(name: String, city: String?) {
        var q = name
        if let city, !city.isEmpty { q += ", \(city)" }
        guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?q=\(encoded)") else { return }
        openURL(url)
    }

    private func startPollingIfLive() {
        guard game.isLive else { return }
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
                if let updated = try? await ESPNService.shared.refreshGame(id: game.id, on: game.date) {
                    game = updated
                    if !updated.isLive { break }
                }
            }
        }
    }
}
