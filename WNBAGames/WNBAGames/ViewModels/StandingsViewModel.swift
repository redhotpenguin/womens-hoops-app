import Foundation

@MainActor
final class StandingsViewModel: ObservableObject {
    @Published var conferences: [Conference] = []
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

    func load() async {
        guard loadingState != .loading else { return }
        loadingState = .loading
        do {
            let fetched = try await service.fetchStandings()
            conferences = fetched
            loadingState = .loaded
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }

    func refresh() {
        Task { await load() }
    }
}
