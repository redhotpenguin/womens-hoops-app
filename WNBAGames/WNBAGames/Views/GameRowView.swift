import SwiftUI

struct GameRowView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 0) {
                TeamLabel(team: game.awayTeam)
                Text("  @  ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TeamLabel(team: game.homeTeam)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(game.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(game.formattedTime)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }

            HStack(spacing: 4) {
                if let venue = game.venueName {
                    Text(venue)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
                if game.networks.isEmpty {
                    Text("TBD")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(game.networks, id: \.rawValue) { network in
                        NetworkBadgeView(network: network)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct TeamLabel: View {
    let team: Team

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(team.primaryColor ?? Color.secondary.opacity(0.5))
                .frame(width: 9, height: 9)
            Text(team.abbreviation)
                .font(.subheadline.weight(.semibold))
        }
    }
}
