import Foundation

@MainActor
final class GamesViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var loadingState: LoadingState = .idle

    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private let service: ESPNService

    init(service: ESPNService = .shared) {
        self.service = service
    }

    func loadGames() async {
        guard loadingState != .loading else { return }
        loadingState = .loading
        do {
            let fetched = try await service.fetchUpcomingGames(limit: 10)
            games = fetched
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }

    func refresh() {
        Task { await loadGames() }
    }
}
