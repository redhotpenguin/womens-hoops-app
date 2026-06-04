import SwiftUI

struct MenuBarPopoverView: View {
    @StateObject private var viewModel = GamesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(width: 480, height: 460)
        .task { await viewModel.loadGames() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("WNBA Games")
                    .font(.headline)
                Text("Next 10 scheduled games")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                viewModel.refresh()
            } label: {
                if viewModel.loadingState == .loading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.loadingState == .loading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            EmptyStateView(state: .loading)
                .frame(height: 120)

        case .error(let message):
            EmptyStateView(state: .error(message)) {
                viewModel.refresh()
            }
            .frame(height: 120)

        case .loaded where viewModel.games.isEmpty:
            EmptyStateView(state: .noGames)
                .frame(height: 120)

        case .loaded:
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.games) { game in
                        GameRowView(game: game)
                            .padding(.horizontal, 14)
                        Divider()
                            .padding(.horizontal, 14)
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }
}
