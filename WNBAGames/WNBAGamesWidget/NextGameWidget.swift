import WidgetKit
import SwiftUI

struct NextGameEntry: TimelineEntry {
    let date: Date
    let game: Game?
}

struct NextGameProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextGameEntry {
        NextGameEntry(date: Date(), game: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextGameEntry) -> Void) {
        completion(NextGameEntry(date: Date(), game: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextGameEntry>) -> Void) {
        Task {
            let next = try? await ESPNService.shared.fetchUpcomingGames(limit: 1).first
            let entry = NextGameEntry(date: Date(), game: next)
            let refresh = Date().addingTimeInterval(60 * 60)
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }
}

struct NextGameWidget: Widget {
    let kind: String = "NextGameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextGameProvider()) { entry in
            if #available(iOS 17.0, *) {
                NextGameEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                NextGameEntryView(entry: entry)
                    .padding()
            }
        }
        .configurationDisplayName("Next Game")
        .description("Shows the next upcoming women's pro basketball matchup.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextGameEntryView: View {
    let entry: NextGameEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let game = entry.game {
            switch family {
            case .systemSmall: small(game)
            case .systemMedium: medium(game)
            default: small(game)
            }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "sportscourt")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No upcoming games")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func small(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NEXT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                teamDot(game.awayTeam)
                Text(game.awayTeam.abbreviation).font(.headline)
            }
            HStack(spacing: 8) {
                teamDot(game.homeTeam)
                Text(game.homeTeam.abbreviation).font(.headline)
            }
            Spacer(minLength: 0)
            Text(game.formattedDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(game.formattedTime)
                .font(.caption.weight(.semibold))
        }
    }

    private func medium(_ game: Game) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NEXT GAME")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    teamDot(game.awayTeam)
                    Text(game.awayTeam.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                HStack(spacing: 10) {
                    teamDot(game.homeTeam)
                    Text(game.homeTeam.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(game.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(game.formattedTime)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.trailing)
                if let net = game.networks.first {
                    Text(net.displayName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(net.brandColor.opacity(0.15))
                        .foregroundStyle(net.brandColor)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func teamDot(_ team: Team) -> some View {
        Circle()
            .fill(team.primaryColor ?? Color.secondary.opacity(0.5))
            .frame(width: 10, height: 10)
    }
}
