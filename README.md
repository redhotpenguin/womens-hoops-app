# Women's Hoops

A women's pro basketball companion app for iPhone — schedule, standings, league leaders, and where to watch.

<!-- Add screenshot here -->

## Features

- **Games tab** — the next two weeks of games with date, tip-off time (in your local timezone), venue, and broadcast networks. Tap a venue to open Apple Maps.
- **Watch Online** — per-game list of networks (ESPN, ABC, Prime Video, Peacock, ION, CBS, NBC, USA Network, and League Pass), Apple TV indicators, tap to open the streaming site.
- **Watch Nearby** — finds the 5 closest sports bars to your current location using on-device CoreLocation + MapKit search.
- **Game Detail** — matchup, live score polling (every 30 seconds for in-progress games), broadcast list, "Remind me 1 hour before tip-off" (local notification), and "Add to Calendar" (EventKit).
- **Standings tab** — Western and Eastern conference standings with rank, W/L, win %, and games-behind. Tap a team to drill into its upcoming + recent games.
- **Leaders tab** — Top 20 across Points, Rebounds, Assists, Steals, and Blocks.
- **Settings tab** — favorite-team picker (filters the Games list to "My Team"), share-the-app sheet (AirDrop), and trademark/privacy attribution.
- **Home Screen widget** — "Next Game" widget in small and medium sizes; refreshes hourly.
- Golden State Valkyries highlighted throughout in team purple.

## Requirements

- iOS 16 or later (iPhone)
- Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) to build from source

## Building from source

```bash
git clone https://github.com/redhotpenguin/womens-hoops-app.git
cd womens-hoops-app/WNBAGames
xcodegen generate
open WNBAGames.xcodeproj
```

## Data source

Game data, standings, and leaders come from ESPN's public sports API — no API key required.

## Privacy

The app collects no PII and contains no third-party analytics or tracking SDKs. Location is used only when you tap **Watch Nearby**, and is sent only to Apple's MapKit search to find sports bars near you. Calendar access (when you tap **Add to Calendar**) is write-only. See [PRIVACY.md](PRIVACY.md) for the full policy.

## Legal

Team names, logos, and colors are trademarks of their respective owners. This application is an independent product and is not affiliated with, endorsed by, or sponsored by any professional basketball league or its member teams. Schedule, standings, and leader data are sourced from ESPN's public API.

## License

MIT — see [LICENSE](LICENSE)
