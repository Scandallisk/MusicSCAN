# MusicSCAN changelog

## 0.7.1 BETA — 2026-10-22

Fix recovery after loading screens, including a reported Delve-to-Silvermoon hearth.

- Restore the active MusicSCAN track after a loading-screen transition.
- Wait for loading to finish, then allow one second for zone audio to initialize.
- Keep the active track even when another row is highlighted.
- Cancel pending restoration on Stop, explicit Play, a subsequent transition or logout.
- Ignore stale callbacks so a canceled request cannot override a later choice.
- Clear the Playing display when recovery fails or Sound / Music is disabled.
- Preserve idle behavior after login and reload, Favorites and the existing catalog.

Recovery restarts the audio file; exact-position seeking is not available.
Local mocked lifecycle and catalog regression checks pass. In-game recovery
confirmation is pending; the 0.7.0 client checks remain the prior baseline.

## 0.7.0 BETA — 2026-10-21

First packaged beta, built from the tested 0.7.0 Favorites milestone.

- Added a clickable outline / filled star that targets the highlighted selection.
- Added an alphabetical Favorites category below expansion categories, with a count
  and independent expand / collapse control.
- Saved favorites account-wide by audio FileDataID; retention across reload was
  confirmed in-game.
- Included favorites in search and added the exact Favorites search shortcut.
- Preserved normal category fold choices while searching.
- Retained the 5,493-entry music catalog, chronological expansion groups,
  alphabetical zones and tracks, native repetition, Play / Stop and saved layout.
- Separated the installable addon from catalog tooling and publishing assets.
- Added release documentation, source notes and coordinated MusicSCAN artwork.

Favoriting changes the saved list without starting, stopping or switching music.
The beta packaging changes version labels and comments without altering tested
playback or preference behavior.

## 0.6.0 — 2026-10-21

- Expanded the catalog from 13 to 5,493 individual audio FileDataIDs across 12
  expansion categories, using a pinned listfile and zone-music metadata snapshot.
- Excluded explicit effects, voice, scene and other non-background cues.
- Removed Test badges from track names and tooltips.
- Added expansion counts, cached search metadata and recycled visible rows.
- Preserved stable selection keys and playback behavior.

## 0.5.1 — 2026-10-21

- Ordered expansion headings by original release sequence, including search results.
- Kept zones and tracks alphabetical inside each expansion.

## 0.5.0 — 2026-10-21

- Added collapsible expansion categories and saved normal fold preferences.
- Revealed matching search results without overwriting those preferences.
- Removed estimated playback timing, the progress bar and the Loop Music control.
- Used native music repetition with explicit Stop instead of scheduled replay.

## 0.4.1 — 2026-10-21

- Fixed title-icon tooltip clipping by opening toward the player and clamping it.
- Added direct playback confirmations for The Dreamer Variation A and Boralus.

## 0.4.0 — 2026-10-21

- Added the monk-green Now Playing heading and versioned player footer.
- Added author, website and version tooltips to the title icon.
- Investigated reference-file timing, later removed in 0.5.0 after in-game variance.

## 0.3.0 — 2026-10-21

- Added a bottom-right resize grip, responsive anchors and saved window dimensions.
- Extended reset to restore default window size and minimap placement.

## 0.2.0 — 2026-10-21

- Added 12 cross-expansion music candidates to the verified baseline track.
- Preserved the initial player, minimap and preferences.

## 0.1.0 — 2026-10-21

- Created the standalone addon with separate database, core and UI files.
- Added Magnificent Desolation, search, Play / Stop, a movable player and minimap launcher.
- Added SavedVariables and the musicscan / msc slash commands.
