# TODO

## Context

The iOS build of WNBA Games was rejected by Apple under **Guideline 4.2 (Minimum Functionality)**:

> The usefulness of the app is limited by the minimal functionality it currently provides. Specifically, the app does not provide sufficient content and features to be useful, unique, and "app-like."

Resubmission Parts A + B are merged (see `PLAN.md`): "Upcoming 2 weeks" header, venue → Apple Maps, TZ on times, UTM on broadcast links, Watch Online + Watch Nearby, tab bar (Games / Standings / Settings), game detail with live polling, standings with rank + Valkyries tint, team detail, 1h-before local notifications, Home Screen widget, recolored icon, motivation/trademark copy.

This file tracks what's left.

---

## Ship-critical (do before resubmitting to App Store)

### S1. Verify widget builds and installs
- Run `xcodegen generate` clean.
- Build `WNBAGamesWidget` target, confirm no errors.
- On a real device or simulator, long-press Home Screen → Add Widget → search "WNBA Games" → confirm "Next WNBA Game" appears with small + medium options.
- Verify the widget actually shows a real upcoming matchup, not the placeholder.
- If the iOS 16 path (no `containerBackground`) renders poorly, decide whether to bump the widget extension's deployment target to iOS 17.

### S2. Bump version to 1.1
- Update `WNBAGamesIOS/Info.plist` → `CFBundleShortVersionString` to `1.1`, `CFBundleVersion` to `2` (or whatever's next).
- Mirror in `WNBAGamesWidget/Info.plist`.
- Bake `1.1` into the `SettingsView` displayed string (it already reads from `Info.plist`, so this should be automatic — verify).

### S3. Refresh App Store screenshots
- Required device sizes for App Store Connect: 6.7" (iPhone 15 Pro Max) and 6.5" (iPhone 11 Pro Max), plus iPad 13" if you keep iPad as a destination.
- Capture: Games list with header + pills, Game Detail (live game if available, otherwise upcoming), Standings (both conferences visible), Team Detail, Watch Nearby results, Widget on Home Screen.
- Drop into `screenshots/` organized by device size. Update App Store Connect listing.

### S4. Resolve widget Release signing
- `project.yml` references provisioning profile `"WNBA Games Widget App Store"` for the widget's Release config, but that profile doesn't exist in the developer portal yet.
- Create the App ID `com.phred.WNBAGamesIOS.widget` in developer.apple.com, generate a distribution profile, install it, and verify the archive succeeds.
- Without this, App Store archive will fail at the widget step.

### S5. App Review reply
- In App Store Connect → App Review notes, explain what changed between 1.0 (rejected) and 1.1:
  - Tab bar restructure (Games / Standings / Settings)
  - Detail page with live scores and box-score-style content
  - WNBA standings tab
  - Team detail pages drilled in from standings
  - Local notifications for game reminders
  - Location-based "Watch Nearby" sports-bar finder (genuinely new utility)
  - Home Screen widget
- A clear "here's what we added" reply tends to land better than a silent resubmission.

### S6. Fix App Store Support URL (Guideline 1.5 — Safety)
App Review rejected the Support URL `https://github.com/redhotpenguin/wnba_menubar_app/issues` because it doesn't direct users to a webpage they can use to ask questions and get support. Need a real support page.

**Recommended host: Vercel** (free Hobby tier, custom domain support, one-file deploy). Steps:
1. Create a single static HTML page at the repo root (e.g. `support/index.html`) with:
   - App name + one-sentence description
   - Contact email as a `mailto:` link (the address Apple will route review correspondence to also works)
   - Short FAQ (3–5 entries: location use, notifications, where data comes from, how to delete the app, version info)
   - Link to Privacy info
2. Connect the repo to Vercel (`vercel.com/new`), point the project root or a `/support` subdir, deploy.
3. Add a subdomain (e.g. `support.lakeswnbagames.com`) — Vercel guides you through DNS setup for the apex domain you control.
4. Update App Store Connect → App Information → **Support URL** to the new URL. Verify it resolves in an incognito window before resubmitting.

**Alternatives if Vercel isn't preferred:**
- **GitHub Pages** — free, URL would be `https://redhotpenguin.github.io/wnba_menubar_app/`. Works for App Review but less branded.
- **Carrd.co free tier** — single-page sites with their branding subdomain.
- **Notion public page** — looks ok but loads slowly on cold cache.
- **Zendesk free plan** — no longer exists; their free plan was discontinued. Not an option without paying.

### S7. Privacy manifest sanity check
- We added `NSLocationWhenInUseUsageDescription` — confirm the language in `Info.plist` matches what the user sees and what we use location for.
- Review `PrivacyInfo.xcprivacy` (already in the iOS folder) — should disclose the location collection category and the API reasons we hit.

---

## Quick wins (build these before shipping if time allows)

### Q1. Share App via ShareLink + AirDrop
**Goal:** any user can AirDrop / Message / Mail an App Store link to a friend in one tap.

**Implementation (~10 lines, iOS 16+):**
```swift
ShareLink(
    item: URL(string: "https://apps.apple.com/app/id<PLACEHOLDER>")!,
    subject: Text("WNBA Games"),
    message: Text("Check out WNBA Games — schedule, standings, and where to watch.")
) {
    Label("Share App", systemImage: "square.and.arrow.up")
}
```

**Placement:**
- Settings tab → About section row "Share WNBA Games" (discoverable).
- Games tab → trailing toolbar button (icon-only, higher visibility).

**App Store URL caveat:** The link won't resolve until the app is approved. Two options:
- (a) Reserve the App ID in App Store Connect first, bake `https://apps.apple.com/app/id<that-id>` into the build now. Link 404s until approval but no code change required after.
- (b) Ship Q1 pointing at LakesWnbaGames.com, swap in the App Store URL in a 1.1.1 patch after approval.

Recommend (a) if the App Store Connect entry has an ID assigned.

### Q2. Add to Calendar (EventKit) on Game Detail
**Goal:** "Add to Calendar" row in `GameDetailView`'s broadcast/action section creates a calendar event for the game.

**Implementation:**
- New `CalendarManager` (or inline helper) using `EKEventStore.requestWriteOnlyAccessToEvents` (iOS 17+) with fallback to `requestAccess(to: .event)` for iOS 16.
- Event fields: title `"<away.displayName> at <home.displayName>"`, start = `game.date`, end = `game.date + 2.5h`, location = `venueName, venueCity`, notes = networks joined with ", ".
- On success, show a brief "Added to Calendar" confirmation (haptic + transient label state).

**Plist key:** `NSCalendarsWriteOnlyAccessUsageDescription` (iOS 17) and/or `NSCalendarsUsageDescription` (iOS 16 fallback) — text like "Add WNBA games to your calendar so you don't forget tip-off."

**Placement:** above the existing "Remind me 1 hour before" toggle in `GameDetailView`.

### Q3. Favorite team + Games list filter
**Goal:** user picks one favorite team in Settings; Games list gains a "My Team / All" toggle and notifications auto-arm for that team.

**Implementation:**
- `FavoriteTeamStore` (ObservableObject, @MainActor) backed by `UserDefaults` key `favoriteTeamID`. Exposes `@Published var teamID: String?` and a helper `isFavorite(_ team: Team)`.
- In `SettingsView`, new section "Favorite Team" with a Picker over the 13 teams. Use the team list from the standings fetch as the source of truth (fall back to a hard-coded list if standings haven't loaded).
- In `GamesListView`, add a segmented control above the list: `[My Team] [All]`. Default to `All` if no favorite; default to `My Team` once one is chosen.
- In `GameRowView`, optionally tint the favorite team's name (small star icon next to the abbreviation).
- Optional follow-up (do it after the basic filter works): when the user sets a favorite, auto-schedule 1h reminders for all upcoming favorite-team games (toggleable on the Settings row).

### Q4. League Leaders as a fourth tab
**Goal:** add a "Leaders" tab showing PPG / RPG / APG top 10.

**Implementation:**
- New `WNBAGames/Models/Leader.swift` (`struct Leader { let player: String; let teamAbbr: String; let value: Double }`).
- ESPN endpoint: `https://site.api.espn.com/apis/site/v2/sports/basketball/wnba/leaders` — returns categories with athlete + statValue.
- New `LeadersViewModel` mirroring `StandingsViewModel`.
- New `WNBAGamesIOS/LeadersView.swift` with a Picker for the stat category (Points / Rebounds / Assists / Steals / Blocks) and a List of top 10 per category. Show rank, player name, team abbr, value.
- Add to `RootTabView` between Standings and Settings: `Label("Leaders", systemImage: "trophy")`.

---

## Deferred (post-resubmission polish)

### Live scores polling on the list
`Game.status` already exists. Detail page polls the ESPN summary every ~30s for live games — lift that into the list view (rows show a live score badge). Watch battery/network — gate by `.onAppear`/`.onDisappear`.

### News headlines
ESPN exposes a WNBA news feed. Section on the Games tab or its own tab. Held back as redundant with standings/detail for 4.2 purposes; useful for engagement.

### Search / filter by network
Top-bar filter on the Games list ("Show only games on ESPN / Prime / etc."). Small, useful.

### Push notifications (server-side)
Real-time alerts for news, lineup changes, score updates. Requires APNs infra; local notifications cover the most important reminder use case for now.

### iPad layout polish
`NavigationSplitView` for iPad: games list on left, detail on right. Currently the app uses the compact layout on iPad too.

### macOS parity for new screens
Standings / Detail / Team views could be brought to the macOS popover, but the menu-bar form factor may not be the right home. A separate macOS window app would be cleaner if we want full parity.

### App icon refresh
Current icon is hue-shifted purple. Consider commissioning a polished, distinctive icon for App Store browse appeal.
