import SwiftUI

enum GameDestination: Hashable {
    case online(Game)
    case nearby(Game)
}

struct GamesListView: View {
    @StateObject private var viewModel = GamesViewModel()
    @State private var path: [GameDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("WNBA Games")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.loadingState == .loading {
                            ProgressView()
                        }
                    }
                }
                .navigationDestination(for: GameDestination.self) { dest in
                    switch dest {
                    case .online(let game): WatchOnlineView(game: game)
                    case .nearby(let game): WatchNearbyView(game: game)
                    }
                }
        }
        .task { await viewModel.loadGames() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle:
            EmptyStateView(state: .loading)
        case .loading where viewModel.games.isEmpty:
            EmptyStateView(state: .loading)
        case .error(let message):
            EmptyStateView(state: .error(message)) {
                viewModel.refresh()
            }
        case .loaded where viewModel.games.isEmpty:
            EmptyStateView(state: .noGames)
        default:
            List {
                Section {
                    ForEach(viewModel.games) { game in
                        GameRowView(
                            game: game,
                            onShowOnline: { path.append(.online(game)) },
                            onShowNearby: { path.append(.nearby(game)) }
                        )
                    }
                } header: {
                    Text("Upcoming 2 weeks of games")
                        .font(.subheadline)
                        .textCase(nil)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadGames()
            }
        }
    }
}
