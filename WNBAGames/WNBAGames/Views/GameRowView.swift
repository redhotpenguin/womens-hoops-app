import SwiftUI
#if os(macOS)
import AppKit
#endif

struct GameRowView: View {
    let game: Game
    #if os(iOS)
    var onShowOnline: (() -> Void)? = nil
    var onShowNearby: (() -> Void)? = nil
    #endif
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

            bottomRow
        }
        .padding(.vertical, 6)
        .background {
            if let color = gsColor {
                color.opacity(0.25)
            }
        }
    }

    @ViewBuilder
    private var bottomRow: some View {
        #if os(iOS)
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
            Button {
                onShowOnline?()
            } label: {
                actionPill(label: "Online", icon: "play.rectangle.fill")
            }
            .buttonStyle(.borderless)
            Button {
                onShowNearby?()
            } label: {
                actionPill(label: "Nearby", icon: "mappin.and.ellipse")
            }
            .buttonStyle(.borderless)
        }
        #else
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
        #endif
    }

    #if os(iOS)
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
    #endif
}

private struct TeamLabel: View {
    let team: Team
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let url = team.websiteURL {
            Button { openURL(url) } label: { chip }
                .buttonStyle(.plain)
                #if os(macOS)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                #endif
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
