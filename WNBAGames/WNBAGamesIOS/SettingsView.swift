import SwiftUI

struct SettingsView: View {
    @StateObject private var favorites = FavoriteTeamStore.shared

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var favoriteBinding: Binding<String?> {
        Binding(
            get: { favorites.abbreviation },
            set: { favorites.abbreviation = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(versionString)
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://redhotpenguin.github.io/wnba_games_app_ios/")!) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    ShareLink(
                        item: AppShare.url,
                        subject: Text("WNBA Games"),
                        message: Text(AppShare.message)
                    ) {
                        Label("Share WNBA Games", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Favorite Team") {
                    Picker("Favorite", selection: favoriteBinding) {
                        Text("None").tag(String?.none)
                        ForEach(WNBATeamCatalog.all) { team in
                            Text(team.displayName).tag(String?(team.abbreviation))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Motivation") {
                    Text("We built this app to promote women's basketball. You might be able to tell our favorite team if you look close enough. This app has no cookies, doesn't collect PII, doesn't sell your data. If you want cookies, go to the cookie shop.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Text("Scores, schedule, and broadcast information are provided by ESPN's public WNBA API.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Text("Location is requested only when you tap Watch Nearby, and is used solely to search for sports bars near you.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Trademarks") {
                    Text("WNBA is a trademark of the Women's National Basketball Association, LLC. Team names and logos are trademarks of their respective owners. This app is not affiliated with, endorsed by, or sponsored by the WNBA or any team.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
