# iOS App: App Store Resubmission Plan

## Context

The iOS target (`WNBAGames/WNBAGamesIOS/`) shares views with the macOS menu-bar app. The iOS build was **rejected by Apple under Guideline 4.2 (Minimum Functionality)** — the reviewer felt it was a thin wrapper around the list. This plan addresses two things in one pass:

1. The originally requested polish items (header, venue links, UTM, TZ, Watch Online/Nearby).
2. A meaningful expansion of app-like surface area (tabs, standings, detail pages, notifications, widget) to clear the 4.2 bar.

iOS-only unless noted. macOS menu-bar UI must not regress; shared-file edits stay backward-compatible.

Design decisions captured up-front:
- Buttons live **per-game row**, replacing the network badges area on iOS.
- Venue tap opens **Apple Maps** via native URL scheme.
- Timezone abbreviation reflects **the user's local TZ**.

---

## Part A — Original polish items

### A1. "Upcoming 2 weeks of games" header (iOS)

In `WNBAGamesIOS/GamesListView.swift`, wrap the loaded `List` in a `Section` with header:

```swift
List {
    Section {
        ForEach(viewModel.games) { game in
            NavigationLink { GameDetailView(game: game) } label: {
                GameRowView(game: game)
            }
        }
    } header: {
        Text("Upcoming 2 weeks of games")
            .font(.subheadline)
            .textCase(nil)
    }
}
```

(Row is now a NavigationLink — see A5/B2.)

### A2. Timezone next to time (shared)

In `WNBAGames/Models/Game.swift`, modify `formattedTime`:

```swift
var formattedTime: String {
    let f = DateFormatter()
    f.timeStyle = .short
    f.timeZone = .current
    let time = f.string(from: date)
    let tz = TimeZone.current.abbreviation(for: date) ?? ""
    return tz.isEmpty ? time : "\(time) \(tz)"
}
```

Additive — macOS popover also gains the suffix.

### A3. UTM parameter on outbound links (shared)

In `WNBAGames/Models/BroadcastNetwork.swift`, route every URL through:

```swift
private func tagged(_ s: String) -> URL? {
    guard var c = URLComponents(string: s) else { return nil }
    var items = c.queryItems ?? []
    items.append(URLQueryItem(name: "utm_source", value: "wnba_games_app_ios"))
    c.queryItems = items
    return c.url
}
```

Apply in every `watchURL` case. Single chokepoint for badges, Watch Online page, and any future link.

### A4. Venue link → Apple Maps (iOS only)

In `WNBAGames/Views/GameRowView.swift`, gate the venue tap behind `#if os(iOS)` so macOS behavior is unchanged. Builds `http://maps.apple.com/?q=<venue>,<city>` URL-encoded and opens with `@Environment(\.openURL)`.

### A5. Watch Online button + page (per row, iOS only)

`GameRowView` on iOS replaces the network badges HStack with two pill buttons sized to match `NetworkBadgeView` styling. New file `WNBAGamesIOS/WatchOnlineView.swift`:
- Takes `Game`.
- Lists `game.networks` as styled list rows (reuse `NetworkBadgeView` or a row variant).
- Each row taps to the UTM-tagged `watchURL`.
- Empty state: "No online broadcasts announced for this game."

### A6. Watch Nearby button + page (per row, iOS only)

New file `WNBAGamesIOS/WatchNearbyView.swift`:
- `CLLocationManager.requestWhenInUseAuthorization()` on appear.
- `MKLocalSearch` with `naturalLanguageQuery = "sports bar"`, region ~5 km around user.
- Sort by distance, take top 5; show name, address, distance.
- Tap row → `mapItem.openInMaps()`.
- States: not-determined CTA, denied (settings deep link), no results.

Add to `WNBAGamesIOS/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to find sports bars near you that are showing the game.</string>
```

---

## Part B — App Store 4.2 resubmission expansion

### B1. Tab bar navigation (iOS root)

Replace the single `GamesListView` root in `WNBAGamesIOSApp.swift` with a `TabView`:

```swift
TabView {
    GamesListView()
        .tabItem { Label("Games", systemImage: "basketball") }
    StandingsView()
        .tabItem { Label("Standings", systemImage: "list.number") }
    SettingsView()
        .tabItem { Label("Settings", systemImage: "gear") }
}
```

Three tabs is the minimum "real app" shape; cheap and high-signal for review.

### B2. Game detail page (iOS)

New file `WNBAGamesIOS/GameDetailView.swift`. Each list row becomes a `NavigationLink` into this view. Contents:
- Header: matchup, date+time+TZ, venue (Apple Maps link).
- Status section: scheduled / in-progress (live score, quarter, time remaining) / final (final score).
- Broadcasts section: list of networks with tap-through.
- Box score section (final games only): pulled from ESPN summary endpoint.
- Action row: "Notify me 1 hour before" (B5), "Add to Calendar" (deferred — see TODO).
- Watch Online and Watch Nearby links (already from A5/A6) move here as full-width buttons; the row in the list can keep compact buttons or just show NavigationLink chevron.

ESPN summary endpoint: `https://site.api.espn.com/apis/site/v2/sports/basketball/wnba/summary?event=<gameId>`. Add a method to `ESPNService` returning a `GameSummary` struct (boxscore + status). Polled every ~30s when the detail view is visible and the game is live.

### B3. Standings tab (iOS)

New files `WNBAGamesIOS/StandingsView.swift` and shared `WNBAGames/Models/Standing.swift`. ESPN endpoint:
`https://site.api.espn.com/apis/v2/sports/basketball/wnba/standings`

Display two conferences (Eastern / Western) as sections, with columns: Team, W, L, PCT, GB. Tap a row → `TeamDetailView` (B4).

Add a `fetchStandings()` method to `ESPNService` mirroring the games fetch pattern. Use a `StandingsViewModel` matching the shape of `GamesViewModel` (idle/loading/loaded/error).

### B4. Team detail page (iOS)

New file `WNBAGamesIOS/TeamDetailView.swift`. Inputs: a `Team` (already in the model). Contents:
- Header: team name, logo (if exposed by ESPN), record (from standings cache).
- Upcoming games: filter `viewModel.games` where home or away matches.
- Recent results: a small extra fetch for last 5 games (ESPN scoreboard with `dates=` past window), or stash from standings team schedule endpoint.

Reuse `GameRowView` for the lists.

### B5. Local notifications: "remind me before tip-off"

In `GameDetailView`, add a toggle row "Remind me 1 hour before". Uses `UNUserNotificationCenter`:
- Request `.alert, .sound` authorization on first toggle.
- Schedule a `UNCalendarNotificationTrigger` for `game.date - 1h`.
- Cancel scheduled notification on toggle off.
- Persist enabled game IDs in `UserDefaults` so the toggle state survives launches.

No background fetch, no server — fully local. Add to `Info.plist` only if needed for entitlements (basic local notifs don't require additional plist keys).

### B6. Home Screen widget

New widget extension target `WNBAGamesWidget`:
- `IntentTimelineProvider` (or `TimelineProvider`) that fetches the next upcoming game from ESPN.
- Small + medium widget families: matchup, date/time/TZ, network logo.
- Tap deep-links into the app (URL scheme registered in Info.plist).
- Refresh every ~1 hour.

This is a meaningful App Store signal — Apple's review explicitly weighs widget presence as "app-like."

`project.yml` will need a new target entry. After adding, regenerate the Xcode project with `xcodegen generate`.

---

## Critical files

**Modified (shared):**
- `WNBAGames/Models/Game.swift` — TZ-abbrev in `formattedTime`
- `WNBAGames/Models/BroadcastNetwork.swift` — UTM helper applied in `watchURL`
- `WNBAGames/Views/GameRowView.swift` — iOS-gated venue link + iOS-gated Watch Online/Nearby buttons
- `WNBAGames/Services/ESPNService.swift` — new `fetchStandings()`, `fetchGameSummary(eventId:)`

**Modified (iOS):**
- `WNBAGamesIOS/WNBAGamesIOSApp.swift` — TabView root
- `WNBAGamesIOS/GamesListView.swift` — header section, NavigationLink rows
- `WNBAGamesIOS/Info.plist` — `NSLocationWhenInUseUsageDescription`, widget URL scheme
- `project.yml` — widget target, regen with `xcodegen generate`

**New (iOS):**
- `WNBAGamesIOS/WatchOnlineView.swift`
- `WNBAGamesIOS/WatchNearbyView.swift`
- `WNBAGamesIOS/GameDetailView.swift`
- `WNBAGamesIOS/StandingsView.swift`
- `WNBAGamesIOS/TeamDetailView.swift`
- `WNBAGamesIOS/SettingsView.swift` (minimal: app version, about, link to Apple Maps for HQ-ish, attributions)
- `WNBAGames/Models/Standing.swift` (shared model, harmless on macOS)
- `WNBAGames/ViewModels/StandingsViewModel.swift`
- Widget extension target: `WNBAGamesWidget/` (provider, entry view, bundle)

---

## Verification

1. `xcodegen generate`; build both macOS and iOS targets — shared files still compile cleanly.
2. **iOS Simulator (iPhone 15, iOS 17+):**
   - Tab bar shows Games / Standings / Settings.
   - Games tab: "Upcoming 2 weeks of games" header; rows show time + TZ; tap row → detail page.
   - Detail page: live score for in-progress, box score for finals, broadcasts list, Watch Online + Watch Nearby buttons, "Remind me" toggle that schedules a local notification.
   - Tap venue on detail → Apple Maps opens with search.
   - Watch Online: tap a network → Safari with `?utm_source=wnba_games_app_ios`.
   - Watch Nearby: permission prompt → 5 sorted sports bars → tap opens Apple Maps directions.
   - Standings tab: two conferences, sorted by record, tap team → Team Detail.
   - Team Detail: upcoming + recent games rendered with `GameRowView`.
   - Toggle notification, set device time forward, confirm local notification fires.
   - Add widget to Home Screen, confirm it shows the next game and deep-links into the detail view.
3. **macOS menu-bar:** popover unchanged except for the new TZ suffix on times. Tap a network badge → URL has UTM param.
4. Submit to TestFlight; confirm Apple review notes 4.2 is resolved.
