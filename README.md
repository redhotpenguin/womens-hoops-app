# WNBA Games

WNBA schedule in your Mac menu bar and on your iPhone.

View the next two weeks of upcoming WNBA games — tip-off times, venues, and every broadcast network — with tappable badges that open the streaming site directly.

<!-- Add screenshot here -->

## Features

- Two weeks of scheduled games with date and tip-off time (your local timezone)
- Home and away teams shown as color-coded abbreviations, tap to open the team's website
- Venue for each game
- Broadcast network badges (ESPN, ABC, Prime Video, Peacock, ION, CBS, NBC, USA Network, NBA TV, WNBA League Pass) with brand colors
- Apple TV app indicator on networks that have an Apple TV app
- Tap any badge to open that network's streaming site
- Golden State Valkyries games highlighted in team purple
- Manual refresh (macOS) / pull-to-refresh (iOS)
- macOS: lives only in the menu bar — no Dock icon, no full window

## Requirements

- macOS 13 Ventura or later (menu bar app)
- iOS 16 or later (iPhone app)

To build from source: Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Building from source

```bash
git clone https://github.com/redhotpenguin/wnba_menubar_app.git
cd wnba_menubar_app/WNBAGames
xcodegen generate
open WNBAGames.xcodeproj
```

## Data source

Game data comes from ESPN's public scoreboard API — no API key required.

## Privacy

This app collects no data. See [PRIVACY.md](PRIVACY.md) for the full privacy policy.

## Legal

WNBA and the WNBA logo are trademarks of WNBA Enterprises, LLC. The WNBA team names, logos, and colors are trademarks of their respective teams. This application is not affiliated with, endorsed by, or sponsored by the WNBA, its member teams, or NBA Properties, Inc. Game schedule data is sourced from ESPN's public API.

## License

MIT — see [LICENSE](LICENSE)
