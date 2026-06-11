import Foundation

struct Standing: Identifiable, Hashable {
    let team: Team
    let wins: Int
    let losses: Int
    let winPercent: Double?
    let gamesBehind: Double?

    var id: String { team.id }

    var record: String { "\(wins)-\(losses)" }

    var winPercentDisplay: String {
        guard let p = winPercent else { return "—" }
        return String(format: ".%03d", Int((p * 1000).rounded()))
    }

    var gamesBehindDisplay: String {
        guard let gb = gamesBehind, gb > 0 else { return "—" }
        if gb == gb.rounded() {
            return String(format: "%.0f", gb)
        }
        return String(format: "%.1f", gb)
    }
}

struct Conference: Identifiable, Hashable {
    let name: String
    let standings: [Standing]

    var id: String { name }
}
