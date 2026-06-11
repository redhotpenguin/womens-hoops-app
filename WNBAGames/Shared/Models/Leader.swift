import Foundation

struct LeaderCategory: Identifiable, Hashable {
    let key: String
    let displayName: String
    let leaders: [Leader]

    var id: String { key }
}

struct Leader: Identifiable, Hashable {
    let id = UUID()
    let athleteName: String
    let teamAbbreviation: String?
    let displayValue: String
    let value: Double?

    static func == (lhs: Leader, rhs: Leader) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
