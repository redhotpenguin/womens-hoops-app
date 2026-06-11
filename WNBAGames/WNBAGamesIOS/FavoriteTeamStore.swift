import Foundation
import SwiftUI

@MainActor
final class FavoriteTeamStore: ObservableObject {
    static let shared = FavoriteTeamStore()

    private let storageKey = "favoriteTeamAbbreviation"

    @Published var abbreviation: String? {
        didSet { persist() }
    }

    private init() {
        self.abbreviation = UserDefaults.standard.string(forKey: storageKey)
    }

    func isFavorite(_ team: Team) -> Bool {
        guard let abbr = abbreviation else { return false }
        return team.abbreviation == abbr
    }

    private func persist() {
        if let abbreviation {
            UserDefaults.standard.set(abbreviation, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}

// Stable list of WNBA team abbreviations + display names so Settings has a
// picker even before standings are fetched. Keep aligned with Team.websiteURL.
enum WNBATeamCatalog {
    struct Entry: Identifiable, Hashable {
        let abbreviation: String
        let displayName: String
        var id: String { abbreviation }
    }

    static let all: [Entry] = [
        .init(abbreviation: "ATL", displayName: "Atlanta Dream"),
        .init(abbreviation: "CHI", displayName: "Chicago Sky"),
        .init(abbreviation: "CON", displayName: "Connecticut Sun"),
        .init(abbreviation: "DAL", displayName: "Dallas Wings"),
        .init(abbreviation: "GS",  displayName: "Golden State Valkyries"),
        .init(abbreviation: "IND", displayName: "Indiana Fever"),
        .init(abbreviation: "LV",  displayName: "Las Vegas Aces"),
        .init(abbreviation: "LA",  displayName: "Los Angeles Sparks"),
        .init(abbreviation: "MIN", displayName: "Minnesota Lynx"),
        .init(abbreviation: "NY",  displayName: "New York Liberty"),
        .init(abbreviation: "PHX", displayName: "Phoenix Mercury"),
        .init(abbreviation: "SEA", displayName: "Seattle Storm"),
        .init(abbreviation: "WSH", displayName: "Washington Mystics")
    ]
}
