# WNBA Games Mac Menu Bar App — Implementation Plan

## Context

Build a macOS menu bar application in Swift/SwiftUI that shows the next 10 upcoming WNBA games and where to watch them. The app lives as a compact popover attached to a basketball icon in the menu bar — no Dock icon, no full window. It fetches data from ESPN's public (unofficial, no-key) JSON API.

**Key decisions:**
- Menu bar only (no window scene, no Dock icon)
- Broadcast badges are display-only (no click action in v1; clicking to open streaming site is a planned next step)
- Teams shown as colored dot + abbreviation (no logo image fetching)
- No third-party dependencies — pure Swift/Foundation/SwiftUI

---

## Data Source

**ESPN public scoreboard API** (no API key required):
```
https://site.api.espn.com/apis/site/v2/sports/basketball/wnba/scoreboard?dates=YYYYMMDD-YYYYMMDD&groups=100
```

Query a 45-day window from today, filter to future games only, take the first 10 sorted by date.

**Broadcast networks for 2026 season:** ABC, ESPN, ESPN+, Amazon Prime Video, CBS, ION, NBC, Peacock, USA Network, NBA TV, WNBA League Pass

**Apple TV app availability:**
- ✅ Amazon Prime Video
- ✅ ESPN / ESPN+
- ✅ Peacock
- ✅ CBS / Paramount+
- ✅ NBA TV
- ✅ ABC (via ESPN app)
- ❌ ION (not confirmed on Apple TV)
- ❌ USA Network (not confirmed on Apple TV)

---

## Project Structure

```
WNBAGames/                          ← Xcode project root
├── WNBAGames.xcodeproj/
└── WNBAGames/
    ├── WNBAGamesApp.swift          ← App entry: MenuBarExtra scene only
    ├── Models/
    │   ├── ESPNResponse.swift      ← Codable structs mirroring ESPN JSON
    │   ├── Game.swift              ← Domain model (mapped from ESPN)
    │   └── BroadcastNetwork.swift  ← Enum: known networks + metadata
    ├── Services/
    │   └── ESPNService.swift       ← async fetch → decode → map to [Game]
    ├── ViewModels/
    │   └── GamesViewModel.swift    ← @MainActor ObservableObject, drives all views
    ├── Views/
    │   ├── MenuBarPopoverView.swift ← Root popover view
    │   ├── GameRowView.swift        ← Single game row
    │   ├── NetworkBadgeView.swift   ← Colored pill badge for one broadcast network
    │   └── EmptyStateView.swift     ← Loading / error / no-games states
    └── Extensions/
        └── Color+Hex.swift          ← Parse ESPN's hex color strings
```

**Xcode project settings:**
- macOS deployment target: **13.0** (Ventura) — minimum for `MenuBarExtra` SwiftUI API
- App Sandbox: enabled; Outbound network connections: YES
- `LSUIElement = YES` in Info.plist (suppresses Dock icon)
- No third-party Swift packages

---

## File Details

### `WNBAGamesApp.swift`
Declares only a `MenuBarExtra` scene (`.window` style gives a SwiftUI popover). `LSUIElement` in Info.plist hides the app from the Dock.

```swift
@main
struct WNBAGamesApp: App {
    var body: some Scene {
        MenuBarExtra("WNBA", systemImage: "basketball.fill") {
            MenuBarPopoverView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

---

### `Models/ESPNResponse.swift`
Pure Codable structs that mirror the ESPN JSON tree. No business logic here.

```
ESPNScoreboardResponse
  └── events: [ESPNEvent]
        ├── id: String
        ├── date: String  (ISO8601, UTC)
        ├── name: String
        └── competitions: [ESPNCompetition]
              ├── competitors: [ESPNCompetitor]
              │     ├── homeAway: String  ("home" | "away")
              │     └── team: ESPNTeam
              │           ├── displayName, abbreviation
              │           ├── color: String  (hex, no #)
              │           └── logo: String  (URL)
              ├── broadcasts: [ESPNBroadcast]
              │     ├── names: [String]
              │     └── market: String
              ├── venue: ESPNVenue
              │     ├── fullName: String
              │     └── address: { city, state }
              └── status.type.name: String  ("STATUS_SCHEDULED", etc.)
```

---

### `Models/Game.swift`
Domain model decoupled from ESPN API shape.

```swift
struct Game: Identifiable {
    let id: String
    let date: Date
    let homeTeam: Team
    let awayTeam: Team
    let venueName: String?
    let venueCity: String?
    let networks: [BroadcastNetwork]
    let status: GameStatus  // .scheduled | .inProgress | .final_ | .postponed

    var isUpcoming: Bool { status == .scheduled && date > Date() }
    var formattedDate: String  // "Sat, May 10" in local timezone
    var formattedTime: String  // "7:00 PM" in local timezone
}

struct Team: Identifiable {
    let id: String
    let displayName: String
    let abbreviation: String
    let primaryColor: Color?   // parsed from ESPN hex
}
```

---

### `Models/BroadcastNetwork.swift`
Enum of all known 2026 WNBA broadcast partners.

```swift
enum BroadcastNetwork: String, CaseIterable {
    case espn, espnPlus, abc, amazonPrime, cbs, ion, nbc,
         peacock, usaNetwork, nbaTV, wnbaLeaguePass, unknown
}
```

Each case provides:
- `from(apiName:)` — fuzzy-match raw API string ("Prime Video", "ESPN+", etc.) to enum case
- `displayName` — short label shown in badge (e.g. "Prime Video", "ESPN+")
- `hasAppleTVApp: Bool` — drives the Apple TV icon in the badge
- `brandColor: Color` — badge tint (ESPN red, Prime teal, etc.)
- `watchURL: URL?` — streaming URL (used in the planned v2 click-to-open feature)

---

### `Services/ESPNService.swift`
A Swift `actor` with one public method:

```swift
func fetchUpcomingGames(limit: Int = 10) async throws -> [Game]
```

Steps:
1. Build URL with 45-day date range starting today
2. `URLSession.data(from:)` with 15s timeout
3. `JSONDecoder` → `ESPNScoreboardResponse`
4. `compactMap` each event through mapping (returns nil if date parse fails)
5. Filter `.isUpcoming`, sort by date, take first `limit`

Error type: `ESPNServiceError` (.invalidURL, .networkError(Error), .decodingError(Error))

---

### `ViewModels/GamesViewModel.swift`
`@MainActor final class` conforming to `ObservableObject`.

```swift
@Published var games: [Game] = []
@Published var loadingState: LoadingState = .idle

enum LoadingState { case idle, loading, loaded, error(String) }

func refresh() { Task { await loadGames() } }
```

---

### `Views/MenuBarPopoverView.swift`
Frame: `width: 360, height: 480`.

Layout:
```
┌─────────────────────────────────────────┐
│ WNBA Games                   [Refresh]  │
├─────────────────────────────────────────┤
│ IND @ NY          Sat, May 10  7:00 PM  │
│ Barclays Center        [ESPN] [▶ Prime] │
├─────────────────────────────────────────┤
│ SEA @ LV          Sun, May 11  9:00 PM  │
│ Michelob Ultra Arena            [ION]   │
├─────────────────────────────────────────┤
│  ... 8 more rows                        │
└─────────────────────────────────────────┘
```

Switches on `loadingState` to show `ProgressView`, error + retry button, or scrollable game list.
Uses `.task { await viewModel.loadGames() }` on appear.

---

### `Views/GameRowView.swift`
Each row:
- **Line 1:** `[● IND]  @  [● NY]` — colored dot + abbreviation for each team, date/time right-aligned
- **Line 2:** venue name (tertiary) on left, network badges flush right

---

### `Views/NetworkBadgeView.swift`
Capsule pill badge per network. Shows an `appletv.fill` SF Symbol if `network.hasAppleTVApp`, then `network.displayName`. Styled with `network.brandColor` at 15% opacity fill and 40% opacity border. Tooltip via `.help(...)` describes where to watch.

**No tap/click action in v1.**

---

### `Extensions/Color+Hex.swift`
Parses ESPN's 6-character hex color strings (e.g. `"041E42"`) into SwiftUI `Color` values.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| No network | `networkError` → EmptyStateView with retry button |
| ESPN API down / bad response | `decodingError` → EmptyStateView with retry button |
| API schema changes | `compactMap` in mapping silently drops malformed events |
| 0 upcoming games in 45-day window | `.loaded` with empty array → "No upcoming games" empty state |
| Date parse fails on one event | That event is silently skipped |

---

## Verification Steps

1. Create Xcode project (macOS App, SwiftUI, App Sandbox on, Outbound Connections entitlement, `LSUIElement=YES` in Info.plist)
2. Add all Swift files per the structure above
3. Build & run — basketball icon appears in menu bar; click opens popover
4. Verify games load within ~2s on a network connection
5. Check broadcast badges — correct colors, Apple TV icon on Prime/ESPN/Peacock/CBS rows
6. Test edge cases:
   - Airplane mode → error state + retry button works
   - Refresh button → spinner shows, list reloads

---

## Planned Next Steps (not in v1)

1. **Badge click → open streaming site** — `onTapGesture { openURL(network.watchURL) }` in `NetworkBadgeView`
2. Auto-refresh timer (5-minute interval) in `GamesViewModel`
3. Team logo images via `AsyncImage` fetched from ESPN logo URLs
