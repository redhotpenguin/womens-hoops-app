# App Store Submission Status — Women's Hoops Tracker

_Last updated: 2026-07-18_

## Current state

**Resubmitted to the App Store on 2026-07-18 — awaiting Apple review.**

- Version **1.0, build 3**.
- Addresses the prior **Guideline 4.1(a) (Copycats)** rejection via a rebrand
  away from "WNBA Games": all user-visible league/team trademarks scrubbed from
  metadata and copy.

## Naming (three layers — keep straight)

| Layer | Value | Notes |
|---|---|---|
| App Store listing name | **Women's Hoops Tracker** | Exact "Women's Hoops" was reserved by another account in App Store Connect |
| In-app / Home Screen (`CFBundleDisplayName`) | **Women's Hoops** | Shorter, fits the icon label; binary unchanged so build 3 ships as-is |
| Bundle IDs | `com.phred.WNBAGamesIOS`, `com.phred.WNBAGamesIOS.widget` | Internal, immutable — **do not rename** |

## Signing

- Distribution profiles `WNBA Games App Store` / `WNBA Games Widget App Store`
  (portal labels only) — installed, valid through Jun 2027.
- Cert: `Apple Distribution: FREDERICK CLARK MOYER (3AJVPVCRK8)`, team 3AJVPVCRK8.
- Archive verified: `xcodebuild ... archive` succeeds with the widget `.appex`
  embedded.

## Listing copy (in this repo)

- **Description:** [`app-store-description.md`](app-store-description.md)
- **Reviewer note + subtitle / keywords / promo text + checklist:**
  [`app-review-notes.md`](app-review-notes.md)
- **Support URL:** https://redhotpenguin.github.io/womens-hoops-app/ (GitHub
  Pages, served from `main:/docs`).

## Screenshots

- `../screenshots/iphone-6.5/` (1242×2688) — **the only set App Store Connect
  required** for this submission.
- `../screenshots/iphone-6.9/` (1320×2868) and `../screenshots/ipad-13/` also
  committed.
- 6.5" set was produced by resizing the 6.9" captures (only iOS 26.5 /
  iPhone 17-class simulators are installed; no 6.5"-class sim available).

## Age rating

- No social media, no user-generated content, no messaging — all such
  declarations answered **No**. "Share the app" (system share sheet) and
  external broadcaster/Maps links do not count.

## Known residual risk

- The Favorite Team picker (`WNBAGames/WNBAGamesIOS/FavoriteTeamStore.swift`,
  `WNBATeamCatalog.all`) still lists full team names via `team.displayName`.
  Minor 4.1(a) exposure if a reviewer expands the picker; intentionally left
  unchanged.
