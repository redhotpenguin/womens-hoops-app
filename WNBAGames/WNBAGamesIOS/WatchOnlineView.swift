import SwiftUI

struct WatchOnlineView: View {
    let game: Game
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                if game.networks.isEmpty {
                    Text("No online broadcasts announced for this game yet. Check back closer to tip-off.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(game.networks, id: \.rawValue) { network in
                        row(for: network)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(game.awayTeam.displayName) at \(game.homeTeam.displayName)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(game.formattedDate) · \(game.formattedTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .textCase(nil)
                .padding(.vertical, 4)
            }

            Section {
                Text("Streaming links open in your default browser. We append a tag so we can see which links are used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Watch Online")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for network: BroadcastNetwork) -> some View {
        let url = network.watchURL
        Button {
            if let url { openURL(url) }
        } label: {
            HStack(spacing: 12) {
                NetworkBadgeView(network: network)
                VStack(alignment: .leading, spacing: 2) {
                    Text(network.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if network.hasAppleTVApp {
                        Label("Available on Apple TV", systemImage: "appletv")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if url != nil {
                    Image(systemName: "arrow.up.forward.square")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(url == nil)
    }
}
