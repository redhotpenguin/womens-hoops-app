import SwiftUI

struct GameRowView: View {
    let game: Game
    var onShowOnline: (() -> Void)? = nil
    var onShowNearby: (() -> Void)? = nil
    var onShowDetails: (() -> Void)? = nil
    @Environment(\.openURL) private var openURL

    private var gsColor: Color? {
        if game.homeTeam.abbreviation == "GS" { return game.homeTeam.primaryColor }
        if game.awayTeam.abbreviation == "GS" { return game.awayTeam.primaryColor }
        return nil
    }

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

            HStack(spacing: 6) {
                if let venue = game.venueName {
                    Button {
                        openVenueInMaps(name: venue, city: game.venueCity)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                            Text(venue)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button { onShowOnline?() } label: {
                    actionPill(label: "Online", icon: "play.rectangle.fill")
                }
                .buttonStyle(.borderless)
                Button { onShowNearby?() } label: {
                    actionPill(label: "Nearby", icon: "mappin.and.ellipse")
                }
                .buttonStyle(.borderless)
                Button { onShowDetails?() } label: {
                    actionPill(label: "Details", icon: "info.circle.fill")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 6)
        .background {
            if let color = gsColor {
                color.opacity(0.25)
            }
        }
    }

    private func openVenueInMaps(name: String, city: String?) {
        var query = name
        if let city, !city.isEmpty {
            query += ", \(city)"
        }
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?q=\(encoded)") else { return }
        openURL(url)
    }

    private func actionPill(label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.15))
        .foregroundStyle(Color.accentColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 0.5)
        )
    }
}

private struct TeamLabel: View {
    let team: Team
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let url = team.websiteURL {
            Button { openURL(url) } label: { chip }
                .buttonStyle(.plain)
        } else {
            chip
        }
    }

    private var chip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(team.primaryColor ?? Color.secondary.opacity(0.5))
                .frame(width: 9, height: 9)
            Text(team.abbreviation)
                .font(.subheadline.weight(.semibold))
        }
    }
}
