import SwiftUI

struct StandingsView: View {
    @StateObject private var viewModel = StandingsViewModel()
    @State private var path: [Team] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Standings")
                .navigationDestination(for: Team.self) { team in
                    TeamDetailView(team: team)
                }
        }
        .task {
            if viewModel.conferences.isEmpty {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle, .loading where viewModel.conferences.isEmpty:
            ProgressView("Loading standings…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Couldn't load standings")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { viewModel.refresh() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        case .loaded where viewModel.conferences.isEmpty:
            Text("No standings available.")
                .foregroundStyle(.secondary)
        default:
            List {
                ForEach(orderedConferences) { conference in
                    Section {
                        StandingsHeaderRow()
                        ForEach(Array(conference.standings.enumerated()), id: \.element.id) { index, standing in
                            NavigationLink(value: standing.team) {
                                StandingsRowView(rank: index + 1, standing: standing)
                            }
                            .listRowBackground(rowBackground(for: standing))
                        }
                    } header: {
                        Text(conference.name)
                            .font(.headline)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await viewModel.load() }
        }
    }

    private var orderedConferences: [Conference] {
        viewModel.conferences.sorted { a, b in
            rank(of: a) < rank(of: b)
        }
    }

    private func rank(of conference: Conference) -> Int {
        conference.name.lowercased().contains("west") ? 0 : 1
    }

    private func rowBackground(for standing: Standing) -> Color? {
        let abbr = standing.team.abbreviation.uppercased()
        let name = standing.team.displayName.lowercased()
        let isValkyries = abbr == "GS" || abbr == "GSV" || abbr == "GV"
            || name.contains("valkyries")
        guard isValkyries else { return nil }
        return (standing.team.primaryColor ?? Color.purple).opacity(0.15)
    }
}

private enum StandingsColumn {
    static let rank: CGFloat = 28
    static let win: CGFloat = 28
    static let loss: CGFloat = 28
    static let pct: CGFloat = 44
    static let gb: CGFloat = 32
}

private struct StandingsHeaderRow: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("#")
                .frame(width: StandingsColumn.rank, alignment: .leading)
            Text("Team")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("W").frame(width: StandingsColumn.win, alignment: .trailing)
            Text("L").frame(width: StandingsColumn.loss, alignment: .trailing)
            Text("PCT").frame(width: StandingsColumn.pct, alignment: .trailing)
            Text("GB").frame(width: StandingsColumn.gb, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.trailing, 18) // matches NavigationLink chevron space on data rows
    }
}

private struct StandingsRowView: View {
    let rank: Int
    let standing: Standing

    var body: some View {
        HStack(spacing: 8) {
            Text("\(rank)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: StandingsColumn.rank, alignment: .leading)
                .monospacedDigit()
            HStack(spacing: 8) {
                Circle()
                    .fill(standing.team.primaryColor ?? Color.secondary.opacity(0.5))
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 0) {
                    Text(standing.team.displayName)
                        .font(.body)
                        .lineLimit(1)
                    Text(standing.team.abbreviation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(standing.wins)")
                .frame(width: StandingsColumn.win, alignment: .trailing)
                .monospacedDigit()
            Text("\(standing.losses)")
                .frame(width: StandingsColumn.loss, alignment: .trailing)
                .monospacedDigit()
            Text(standing.winPercentDisplay)
                .frame(width: StandingsColumn.pct, alignment: .trailing)
                .monospacedDigit()
                .font(.callout)
            Text(standing.gamesBehindDisplay)
                .frame(width: StandingsColumn.gb, alignment: .trailing)
                .monospacedDigit()
                .font(.callout)
        }
        .font(.body)
    }
}
