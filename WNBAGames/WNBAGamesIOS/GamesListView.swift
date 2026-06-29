import SwiftUI

enum GameDestination: Hashable {
    case online(Game)
    case nearby(Game)
    case detail(Game)
}

struct GamesListView: View {
    @StateObject private var viewModel = GamesViewModel()
    @StateObject private var favorites = FavoriteTeamStore.shared
    @State private var path: [GameDestination] = []
    @State private var teamFilter: GamesFilter = .all

    enum GamesFilter: Hashable {
        case all
        case favorite
    }

    private var filteredGames: [Game] {
        if teamFilter == .all { return viewModel.games }
        guard let fav = favorites.abbreviation else { return viewModel.games }
        return viewModel.games.filter { game in
            game.homeTeam.abbreviation == fav || game.awayTeam.abbreviation == fav
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Women's Hoops")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.loadingState == .loading {
                            ProgressView()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(
                            item: AppShare.url,
                            subject: Text("Women's Hoops"),
                            message: Text(AppShare.message)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .navigationDestination(for: GameDestination.self) { dest in
                    switch dest {
                    case .online(let game): WatchOnlineView(game: game)
                    case .nearby(let game): WatchNearbyView(game: game)
                    case .detail(let game): GameDetailView(game: game)
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
            VStack(spacing: 0) {
                if favorites.abbreviation != nil {
                    Picker("Filter", selection: $teamFilter) {
                        Text("My Team").tag(GamesFilter.favorite)
                        Text("All").tag(GamesFilter.all)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
                gamesList
            }
            .onAppear {
                if favorites.abbreviation != nil && teamFilter == .all {
                    teamFilter = .favorite
                }
            }
        }
    }

    private var gamesList: some View {
        List {
            Text(listSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .listRowSeparator(.hidden)
            if filteredGames.isEmpty {
                Text("No games match the current filter.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(filteredGames) { game in
                    GameRowView(
                        game: game,
                        onShowOnline: { path.append(.online(game)) },
                        onShowNearby: { path.append(.nearby(game)) },
                        onShowDetails: { path.append(.detail(game)) }
                    )
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadGames()
        }
    }

    private var listSubtitle: String {
        switch teamFilter {
        case .all:
            return "Upcoming 2 weeks of games"
        case .favorite:
            if let fav = favorites.abbreviation,
               let entry = WNBATeamCatalog.all.first(where: { $0.abbreviation == fav }) {
                return "Upcoming 2 weeks · \(entry.displayName)"
            }
            return "Upcoming 2 weeks of games"
        }
    }
}
