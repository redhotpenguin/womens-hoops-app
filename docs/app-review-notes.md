# App Review Notes — Women's Hoops Tracker (v1.0, build 3)

Draft to paste into **App Store Connect → App Review Information → Notes**
for the resubmission that addresses the Guideline 4.1(a) rejection of the
previous build.

---

## Reviewer note (paste this)

Hello, and thank you for the review.

This build addresses the previous rejection under Guideline 4.1(a) (Design –
Spam / Copycats), which flagged metadata resembling a specific professional
league.

What changed in this build:

- **Renamed the app to "Women's Hoops Tracker."** The App Store listing name is
  "Women's Hoops Tracker." On the Home Screen and inside the app the shorter
  form "Women's Hoops" is shown (it fits the icon label); the in-app navigation
  title, share sheets, location prompt, and widget labels all use this generic
  name. Neither form references any professional league or team.
- **Removed league and team trademarks from user-visible metadata and copy.**
  The app description, Settings text, and data-source attribution now use
  generic wording (e.g. "women's basketball," "ESPN's public sports API").
- **Independent-app disclaimer.** Settings and our support/privacy pages state
  that this is an independent product, not affiliated with, endorsed by, or
  sponsored by any professional basketball league or its member teams.

Women's Hoops Tracker is an independent companion app for following women's
professional basketball: it shows the upcoming schedule with local tip-off
times and venues, live scores, standings, statistical leaders, a "Watch
Nearby" sports-bar finder (CoreLocation + MapKit), game reminders, and a Home
Screen widget. Schedule, score, standings, and leader data come from ESPN's
public sports API; no login or account is required.

Please let us know if any further changes are needed. Thank you.

---

## Quick reference for the Connect listing (verify before submitting)

- **App name:** Women's Hoops Tracker (the in-app / Home Screen name is the
  shorter "Women's Hoops").
- **Support URL:** the deployed support page (docs/index.html) — confirm it
  resolves in a private/incognito window.
- **Subtitle** (30 char max, no trademarks): `Scores, standings & schedule`
  (alternatives: `Schedule, scores & standings` · `Schedule & where to watch`).
- **Keywords** (100 char field, comma-separated, hidden from users, no
  trademarks): `basketball,women,scores,standings,schedule,leaders,live,games,tip-off,sports`
- **Description:** confirm no league or team trademarks remain in the public
  metadata fields.
- **Screenshots:** committed under `screenshots/` — 6.9" iPhone
  (`iphone-6.9/`, 1320×2868), 6.5" iPhone (`iphone-6.5/`, 1242×2688), and 13"
  iPad (`ipad-13/`). All show the in-app "Women's Hoops" title.
- **Encryption:** `ITSAppUsesNonExemptEncryption = false` is set in Info.plist,
  so the export-compliance question is answered automatically.
