import SwiftUI
import AppKit

struct NetworkBadgeView: View {
    let network: BroadcastNetwork
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let url = network.watchURL {
            Button {
                openURL(url)
            } label: {
                pill
            }
            .buttonStyle(.plain)
            .help(
                network.hasAppleTVApp
                    ? "Watch on \(network.displayName) · available on Apple TV"
                    : "Watch on \(network.displayName)"
            )
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        } else {
            pill.help(network.displayName)
        }
    }

    private var pill: some View {
        HStack(spacing: 4) {
            if network.hasAppleTVApp {
                Image(systemName: "appletv.fill")
                    .font(.system(size: 9))
            }
            Text(network.displayName)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(network.brandColor.opacity(0.15))
        .foregroundStyle(network.brandColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(network.brandColor.opacity(0.4), lineWidth: 0.5)
        )
    }
}
