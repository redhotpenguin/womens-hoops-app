import SwiftUI

struct GamesListView: View {
    @StateObject private var viewModel = GamesViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("WNBA Games")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.loadingState == .loading {
                            ProgressView()
                        }
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
            List(viewModel.games) { game in
                GameRowView(game: game)
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadGames()
            }
        }
    }
}
