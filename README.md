# WNBAGames

WNBA schedule in your Mac menu bar.

Click the basketball icon in the menu bar to see the next 10 upcoming WNBA games, when they tip off, where they're played, and every broadcast network showing the game — with tappable badges that open the streaming site directly.

<!-- Add screenshot here -->

## Features

- Next 10 scheduled games with date and tip-off time (your local timezone)
- Home and away teams shown as color-coded abbreviations
- Venue for each game
- Broadcast network badges (ESPN, ABC, Prime Video, Peacock, ION, CBS, NBC, USA Network, NBA TV, WNBA League Pass) with brand colors
- Apple TV app indicator on networks that have an Apple TV app
- Tap any badge to open that network's site in your browser
- Manual refresh button
- Lives only in the menu bar — no Dock icon, no full window

## Requirements

- macOS 13 Ventura or later

To build from source: Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Installation

Download `WNBAGames.dmg` from [Releases](../../releases), open it, and drag WNBAGames to Applications.

**First launch — Gatekeeper:** The app is ad-hoc signed without an Apple Developer ID, so macOS will block the first launch. Right-click the app → **Open**, then confirm in the dialog. You only need to do this once.

## Building from source

```bash
git clone https://github.com/yourusername/basketball_games.git
cd basketball_games/WNBAGames
xcodegen generate
xcodebuild \
  -project WNBAGames.xcodeproj \
  -scheme WNBAGames \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/WNBAGames-build \
  build
open /tmp/WNBAGames-build/Build/Products/Release/WNBAGames.app
```

## Data source

Game data comes from ESPN's public scoreboard API — no API key required.

## License

MIT
