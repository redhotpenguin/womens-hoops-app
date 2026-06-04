import SwiftUI

struct EmptyStateView: View {
    enum State {
        case loading
        case error(String)
        case noGames
    }

    let state: State
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            switch state {
            case .loading:
                ProgressView()
                Text("Fetching games…")
                    .font(.callout)
                    .foregroundStyle(.secondary)

            case .error(let message):
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if let retry = retryAction {
                    Button("Try Again", action: retry)
                        .buttonStyle(.bordered)
                }

            case .noGames:
                Image(systemName: "basketball")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No upcoming games found.\nCheck back later.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
