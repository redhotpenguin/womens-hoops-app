# TODO — Deferred Items

## Context

The iOS build of WNBA Games was rejected by Apple under **Guideline 4.2 (Minimum Functionality)**:

> The usefulness of the app is limited by the minimal functionality it currently provides. Specifically, the app does not provide sufficient content and features to be useful, unique, and "app-like." Apps should provide valuable utility or entertainment, draw people in by offering compelling capabilities or content, or enable people to do something they couldn't do before or in a way they couldn't do it before.

In response, we built the resubmission plan (see `PLAN.md`) which includes the originally-requested polish items plus six high-leverage app-like expansions: tab bar, game detail, standings, team detail, local notifications, and a Home Screen widget.

The items below were considered for that resubmission but **deferred** — they're either redundant with what we already added, or they're nice polish for a v1.1 once we're approved. Revisit after the resubmission lands.

---

## Deferred from resubmission

### 1. Favorite team + filter
Pick a favorite team in onboarding or Settings; filter the Games list to "My Team" vs "All". Stored in `UserDefaults`. Pairs nicely with B5 (notifications) — auto-subscribe to favorite-team game reminders. Skipped from resubmission because tabs + detail pages were judged to cover the 4.2 bar without adding onboarding complexity.

### 2. Live scores polling on the list (not just detail)
`Game.status` already exists. On the detail page we poll the ESPN summary endpoint every ~30s for live games. Lifting that into the list view (rows show a live score badge) would be a nice "feels alive" touch. Watch out for battery / network on idle screens — wrap in `.onAppear`/`.onDisappear` lifecycle.

### 3. Add to Calendar (EventKit) + Share sheet (`ShareLink`)
On the Game Detail page, two extra rows:
- "Add to Calendar" → EventKit prompt → creates a calendar event with date, venue, and broadcasts in the notes.
- "Share" → `ShareLink` with a formatted string ("Liberty @ Aces — 7:00 PM PDT — Chase Center").
EventKit requires `NSCalendarsFullAccessUsageDescription` in `Info.plist` (iOS 17+).

### 4. League leaders screen
PPG / RPG / APG via ESPN leaders endpoint. Could live as a fourth tab or a section inside Standings. Held back because resubmission scope already adds two new tabs.

### 5. News headlines
ESPN exposes a WNBA news feed. Cheap to wire up as a section on the Games tab or as a "News" tab. Considered redundant with detail/standings for review-bar purposes.

### 6. Search / filter by network
Top-bar filter on the Games list: "Show only games on ESPN / Prime / etc." Small, useful, but not load-bearing for 4.2.

---

## Other ideas worth tracking

- **Push notifications** (server-side) — would let us notify users of news, lineup changes, or score updates without the app being opened. Requires APNs infra; local notifications (B5 in PLAN.md) cover the most important reminder use case for now.
- **iPad layout polish** — split view (games list on left, detail on right) for iPad. Currently the app targets both but uses the same compact layout.
- **macOS parity for new screens** — Standings / Detail / Team views could be added to the macOS popover too, but the menu-bar form factor may not be the right home for them. Consider a separate macOS window app if we want feature parity.
- **App icon refresh** — current icon should be reviewed against Apple's HIG; a polished icon helps perceived quality during review.
- **Screenshots + App Store copy** — once resubmission features land, refresh screenshots in `screenshots/` and the App Store listing to showcase the new tabs, detail page, and widget.
